resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'
developer 'AndersonFabris'
ui_page "nui/index.html"

client_scripts {
	"@vrp/lib/utils.lua",
	"client.lua"
}

server_scripts {
	"@vrp/lib/utils.lua",
	"server.lua"
}

files {
	"nui/images/background.png",
	"nui/index.html",
	"nui/jquery.js",
	"nui/css.css"
}