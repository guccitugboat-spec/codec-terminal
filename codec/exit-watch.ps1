# One-shot: for a Claude session started before the outro was wired up.
# Waits for claude.exe (-ClaudePid) to exit, then plays the outro inside the shell's console (-ShellPid) and closes that tab.
param([int]$ClaudePid, [int]$ShellPid)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type @'
using System; using System.Runtime.InteropServices; using System.Text;
public static class Con {
  [DllImport("kernel32.dll")] public static extern bool FreeConsole();
  [DllImport("kernel32.dll")] public static extern bool AttachConsole(int pid);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern IntPtr CreateFile(string n, uint acc, uint share, IntPtr sa, uint disp, uint flags, IntPtr t);
  [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
  [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] public static extern bool WriteConsoleW(IntPtr h, string s, int n, out int w, IntPtr r);
  [DllImport("kernel32.dll")] public static extern bool GetConsoleScreenBufferInfo(IntPtr h, out CSBI i);
  [StructLayout(LayoutKind.Sequential)] public struct CSBI { public short bx, by, cx, cy; public ushort attr; public short l, t, r, b, mx, my; }
  [StructLayout(LayoutKind.Explicit, CharSet=CharSet.Unicode)] public struct KEY {
    [FieldOffset(0)] public ushort type; [FieldOffset(4)] public int down; [FieldOffset(8)] public ushort rep;
    [FieldOffset(10)] public ushort vk; [FieldOffset(12)] public ushort sc; [FieldOffset(14)] public char ch; [FieldOffset(16)] public uint ctl; }
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] public static extern bool WriteConsoleInputW(IntPtr h, KEY[] r, int n, out int w);
  static IntPtr Open(string n) { return CreateFile(n, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero); }
  public static IntPtr Out() { return Open("CONOUT$"); }
  public static IntPtr In()  { return Open("CONIN$"); }
  public static void Write(IntPtr h, string s) { int w; WriteConsoleW(h, s, s.Length, out w, IntPtr.Zero); }
  public static void Type(IntPtr h, string s) {
    var recs = new KEY[s.Length * 2];
    for (int i = 0; i < s.Length; i++) {
      char c = s[i]; ushort vk = (ushort)(c == '\r' ? 0x0D : char.ToUpper(c));
      recs[2*i]   = new KEY { type = 1, down = 1, rep = 1, vk = vk, ch = c };
      recs[2*i+1] = new KEY { type = 1, down = 0, rep = 1, vk = vk, ch = c };
    }
    int w; WriteConsoleInputW(h, recs, recs.Length, out w);
  }
}
'@
Wait-Process -Id $ClaudePid
Start-Sleep -Milliseconds 300
[Con]::FreeConsole() | Out-Null
if (-not [Con]::AttachConsole($ShellPid)) { exit 1 }
$o = [Con]::Out(); $m = 0; [Con]::GetConsoleMode($o, [ref]$m) | Out-Null; [Con]::SetConsoleMode($o, $m -bor 4) | Out-Null
$e = [char]27
[Con]::Write($o, "$e[?25l$e[3J$e[H$e[2J")
& "$PSScriptRoot\shader-swap.ps1" -To offline
Start-Sleep -Milliseconds 2200
$i = New-Object Con+CSBI; [Con]::GetConsoleScreenBufferInfo($o, [ref]$i) | Out-Null
$w = $i.r - $i.l + 1; $h = $i.b - $i.t + 1; if ($w -lt 10) { $w = 120; $h = 30 }
$msg = 'O F F L I N E'
[Con]::Write($o, "$e[$([int]($h / 2));$([int](($w - $msg.Length) / 2) + 1)H$e[1;38;2;230;60;50m$msg$e[0m")
Start-Sleep -Milliseconds 1600
[Con]::Write($o, "$e[2J$e[?25h")
[Con]::Type([Con]::In(), "exit`r")
Start-Sleep -Seconds 3
& "$PSScriptRoot\shader-swap.ps1" -To matrix
