//
//  Cub+Runner.swift
//  OpenTerm
//
//  Created by Louis D'hauwe on 04/03/2018.
//  Copyright © 2018 Silver Fox. All rights reserved.
//

import Foundation
import Cub

extension Runner {
	
	static func runner(executor: CommandExecutor, executorDelegate: CommandExecutorDelegate, parametersCallback: @escaping ExternalVarCallback) -> Runner {
		
		let runner = Runner(logDebug: false, logTime: false)

		let parametersDoc = """
						An array of values that were passed to this script.
						"""
		
		runner.registerExternalVariable(documentation: parametersDoc, name: "parameters", callback: parametersCallback)
		
		let printDoc = """
						Display something on screen.
						- Parameter input: the value you want to print.
						"""
		
		runner.registerExternalFunction(documentation: printDoc, name: "print", argumentNames: ["input"], returns: true) { (arguments, callback) in
			
			for (_, arg) in arguments {
				
				var input = arg.description(with: runner.compiler)
				input = input.replacingOccurrences(of: "\\n", with: "\n")
				
				if let data = input.data(using: .utf8) {
					executorDelegate.commandExecutor(executor, receivedStdout: data)
				}
			}
			
			Thread.sleep(forTimeInterval: 0.01)
			_ = callback(.number(1))
			return
		}
		
		let readNumberDoc = """
						Pause the script and continue when the user enters a number.
						- Returns: the number that the user entered.
						"""
		
		runner.registerExternalFunction(documentation: readNumberDoc, name: "readNumber", argumentNames: [], returns: true) { (arguments, callback) in
			
			executorDelegate.commandExecutor(executor, waitForInput: { (input) in
				
				if let i = NumberType(input) {
					_ = callback(.number(i))
				} else {
					_ = callback(.number(0))
				}
				
			})

			return
		}
		
		let readLineDoc = """
						Pause the script and continue when the user enters a string.
						- Returns: the string that the user entered.
						"""
		
		runner.registerExternalFunction(documentation: readLineDoc, name: "readLine", argumentNames: [], returns: true) { (arguments, callback) in
			
			executorDelegate.commandExecutor(executor, waitForInput: { (input) in
				_ = callback(.string(input))
			})

			return
		}
		
		let shellCommand = """
						Execute a shell command in the shell that the script is executed from.
						- Parameter command: The command to execute.
						- Returns: the exit code, 0 means no error.
						"""
		
		runner.registerExternalFunction(documentation: shellCommand, name: "shell", argumentNames: ["command"], returns: true) { (arguments, callback) in
			
			var arguments = arguments
			
			guard let command = arguments.removeValue(forKey: "command") else {
				_ = callback(.number(1))
				return
			}
			
			guard case let .string(commandStr) = command else {
				_ = callback(.number(1))
				return
			}

			executorDelegate.commandExecutor(executor, executeSubCommand: commandStr, callback: {
				
				DispatchQueue.main.async {
					
					_ = callback(.number(1))
				}

			})
			
		}

		return runner
	}
	
}
