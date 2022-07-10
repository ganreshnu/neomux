function Start-Neovim {
	$cwd = "/" + ((${PWD} -replace "\\", "/") -replace ":", "")
	$arguments = @()
	$args | ForEach-Object {
		$arg = $_
		if ($arg.StartsWith(".\")) {
			$arg = ($arg -replace "\\", "/")
		}
		$arguments += $arg
	}
	docker run --rm -it -v //var/run/docker.sock://var/run/docker.sock -v ${PWD}:${cwd} -w ${cwd} neovim nvim $arguments
}
Set-Alias -Name vi -Value Start-Neovim
