var page   = require('webpage').create()
var system = require('system')

var signals = {
  'success': 0,
  'missingargs': 1,
  'slowjs': 2,
  'openfailed': 3,
  'resourcetimeout': 4,
  'maxtimeout': 5
}

var maxTimeout = 20000

if (system.args.length === 1) {
  console.log('required args: <siteURL> <waitTime=secs>');
  phantom.exit(signals['missingargs'])
}

var address = system.args[1]
var waitTime = system.args[2] * 1000

page.viewportSize = { width: 1295, height: 960 }
page.clipRect = { top: 0, left: 0, width: 1280, height: 960}

phantom.outputEncoding = 'binary'

page.settings.scriptTimeout = 1000

page.onLongRunningScript = function() {
  page.stopJavaScript()
  phantom.exit(signals['slowjs'])
}

var t = Date.now()

//console.log('Loading ' + address)

setTimeout(function() {
  console.log('timeout')
  phantom.exit(signals['maxtimeout'])
}, maxTimeout)

page.settings.resourceTimeout = maxTimeout

page.onResourceTimeout = function(e) {
  console.log(e.errorCode)
  console.log(e.errorString)
  console.log(e.url)
  phantom.exit(signals['resourcetimeout'])
}

page.open(address, function(status) {
  if(status !== 'success') {
    console.log('failed')
    phantom.exit(signals['openfailed'])
  }

  setTimeout(function() {
    page.render('/dev/stdout', {format: 'jpg', quality: '97'})
    // console.log('Loading time ' + (Date.now() - t) + ' msec');
    phantom.exit(signals['success'])
  }, waitTime)
})
