require('./spec_helper').init exports

PORT = 3000

fs   = require 'fs'
path = require 'path'
sys  = require 'sys'
http = require 'http'
exec = require('child_process').exec
nodeunit = require 'nodeunit'

testAppPath = path.resolve __dirname, '../tmp'
binRailway  = 'cd ' + testAppPath + ' && ' + path.resolve(__dirname, '../bin/railway') + ' '

exists = (test, aPath) ->
    test.ok path.existsSync(path.join(testAppPath, aPath)), 'Not exists: ' + aPath

checkApp = (test, appPath) ->
    appPath = appPath || ''
    process.cwd = () -> path.join(testAppPath, appPath)
    exec 'cd ' + process.cwd() + ' && ' + path.resolve(__dirname, '../bin/railway') + ' ' + 'g crud post title content date:date published:boolean', (err, out) ->
        module = require('module')
        module._cache = {}
        module._pathCache = {}
        start = new Date
        require('nodeunit').runFiles(
            [path.join(testAppPath, appPath, 'test/controllers/posts_controller_test.js')],
            testDone: (name, assertions) ->
                if !assertions.failures()
                    sys.puts '✔ ' + name
                    test.ok(true)
                else
                    test.ok(false, name)
                    sys.puts '✖ ' + name + '\n'
                    assertions.forEach (a) ->
                        if a.failed()
                            a = nodeunit.utils.betterErrors(a)
                            if a.error instanceof AssertionError && a.message
                                sys.puts(
                                    'Assertion Message: ' +
                                    assertion_message(a.message)
                                )
                            sys.puts(a.error.stack + '\n')
            done: (assertions) ->
                end = new Date().getTime()
                duration = end - start
                if assertions.failures()
                    test.ok(false, 'Some assertions fails while controller testing')
                    sys.puts(
                        '\nFAILURES: ' + assertions.failures() +
                        '/' + assertions.length + ' assertions failed (' +
                        assertions.duration + 'ms)'
                    )
                    test.done()
                else
                    sys.puts(
                        '\nOK: ' + assertions.length +
                        ' assertions (' + assertions.duration + 'ms)'
                    )
                    test.done()
        )

# prepare tmp dir
cleanup = (done) ->
    exec 'rm -rf ' + testAppPath, ->
        fs.mkdir testAppPath, 0755, done

# collect test cases
cases = []
cases.push cmd: 'init test-app',   name: 'application with given name', path: 'test-app'
cases.push cmd: 'init --tpl jade', name: 'app using jade templating engine'
cases.push cmd: 'init',            name: 'application in current directory'
cases.push cmd: 'init --coffee',   name: 'coffee-script app'
cases.push cmd: 'init --db redis', name: 'app with redis datastore'
cases.push cmd: 'init --db redis --coffee', name: 'application in current directory'

# run test cases
cases.forEach (testCase) ->
    it 'should init ' + testCase.name, (test) ->
        cleanup ->
            console.log binRailway + testCase.cmd
            exec binRailway + testCase.cmd, (err, out, stderr) ->
                test.ok not err, 'Should be successful'
                checkApp test, testCase.path
