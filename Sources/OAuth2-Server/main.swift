//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectRequestLogger
import PerfectSession
import PerfectSessionPostgreSQL

#if os(Linux)
	let fileRoot = "/perfect-deployed/oauth2-server/"
	var httpPort = 8100
#else
	let fileRoot = ""
	var httpPort = 8181
#endif

var baseURL = ""

// Configuration of Session
SessionConfig.name = "OAuth2Server"
SessionConfig.idle = 3600
SessionConfig.cookieDomain = "localhost"
SessionConfig.IPAddressLock = false
SessionConfig.userAgentLock = false
SessionConfig.CSRF.checkState = true
SessionConfig.CORS.enabled = true
SessionConfig.cookieSameSite = .lax

RequestLogFile.location = "./log.log"
initializeSchema()

let sessionDriver = SessionPostgresDriver()

var confData = [
	"servers": [
		[
			"name":"localhost",
			"port":httpPort,
			"routes":[],
			"filters":[
				[
					"type":"response",
					"priority":"high",
					"name":PerfectHTTPServer.HTTPFilter.contentCompression,
				],
				[
					"type":"request",
					"priority":"high",
					"name":SessionPostgresFilter.filterAPIRequest,
					],
				[
					"type":"request",
					"priority":"high",
					"name":RequestLogger.filterAPIRequest,
					],
				[
					"type":"response",
					"priority":"high",
					"name":SessionPostgresFilter.filterAPIResponse,
					],
				[
					"type":"response",
					"priority":"high",
					"name":RequestLogger.filterAPIResponse,
					]
			]
		]
	]
]


// Add routes
confData["servers"]?[0]["routes"] = mainRoutes()


do {
	// Launch the servers based on the configuration data.
	try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}

