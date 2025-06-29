fx_version 'cerulean'
game 'gta5'

name 'calculator'
author 'Greigh'
description 'Simple calculator phone app for FiveM'
version '1.0.0'

dependencies {
  'qbx_core',
  'ox_lib'
}

shared_scripts {
  '@ox_lib/init.lua',
  '../shared/phone_framework.lua',
  'config.lua'
}

client_scripts {
  'client/client.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/script.js'
}

lua54 'yes'
