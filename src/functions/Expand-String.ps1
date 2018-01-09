function Expand-String {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)][string]$Base64Content
    )

    process {

        $data = [System.Convert]::FromBase64String($Base64Content)
        
        $ms = New-Object System.IO.MemoryStream
        $ms.Write($data, 0, $data.Length)
        $ms.Seek(0, 0) | Out-Null
        
        $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($cs)
        $str = $sr.readtoend()
        return $str
        
    }
}
