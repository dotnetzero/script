function Compress-String {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][string]$StringContent
    )

    process {

        $ms = New-Object System.IO.MemoryStream
        $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
        
        $sw = New-Object System.IO.StreamWriter($cs)
        $sw.Write($StringContent)
        $sw.Close();
        
        $bytes = $ms.ToArray()
        return [System.Convert]::ToBase64String($bytes)

    }
}
