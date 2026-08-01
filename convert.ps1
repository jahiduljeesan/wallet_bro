Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile('C:\Users\hp\.gemini\antigravity-ide\brain\d8ef5ec4-5dfc-4945-9fc5-8fa7d92b1d47\asfak_signature_1785253553405.png')
$img.Save('c:\FP\wallet_bro\Asfak.jpg', [System.Drawing.Imaging.ImageFormat]::Jpeg)
$img.Dispose()
