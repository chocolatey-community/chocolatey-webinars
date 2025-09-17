# https://en.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol

try {
    Invoke-WebRequest "htcpcp://mrcoffee.local" -Method POST <#BREW#> -ErrorAction Stop
} catch {
    throw "May be a teapot."
}