#!/usr/bin/env node

import fs from 'fs';


if( process.env.INIT_CWD === process.cwd() && ! process.env.VITEST ) process.exit();


const source = `${process.env.INIT_CWD}/.flint`;
const destination = `${process.env.INIT_CWD}/node_modules/flint-js/.flint`

if( ! fs.existsSync( source ) && fs.existsSync( destination ) ) fs.cpSync( destination, source, { recursive : true } );
