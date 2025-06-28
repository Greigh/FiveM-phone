fx_version 'cerulean'
game 'gta5'

name 'notes'
author 'Greigh'
description 'Personal notes app for FiveM - create, edit, and manage personal notes'
version '1.0.0'

dependencies {
  -- Framework (one of these)
  -- 'es_extended',
  -- 'qb-core',
  'qbx_core',
  'ox_lib',
  -- Phone System (one of these)
  -- 'lb-phone',
  -- 'qb-phone'
}

shared_scripts {
  '@ox_lib/init.lua',
  '../shared/phone_framework.lua',
  'config.lua'
}

client_scripts {
  'client/client.lua'
}

server_scripts {
  'server/server.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/script.js',
  'html/img/*.png',
  'html/img/*.jpg',
  'html/img/*.svg'
}

lua54 'yes'
