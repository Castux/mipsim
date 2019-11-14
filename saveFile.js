function saveFile(content, path)
{
	var blob = new Blob([content], {type : "text/plain;charset=utf-8"})
	saveAs(blob, path)
}
