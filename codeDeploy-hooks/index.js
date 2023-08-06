'use strict'

const { IncomingWebhook } = require('@slack/webhook')
const AWS = require('aws-sdk')
const codedeploy = new AWS.CodeDeploy({ apiVersion: '2014-10-06' })
const webhook = new IncomingWebhook('https://hooks.slack.com/services/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')

exports.handler = async (event, context, callback) => {
  console.log('Entering AfterAllowTestTraffic hook.')

  // Read the DeploymentId and LifecycleEventHookExecutionId from the event payload
  var deploymentId = event.DeploymentId
  var lifecycleEventHookExecutionId = event.LifecycleEventHookExecutionId
  var validationTestResult = 'Failed'

  // Perform AfterAllowTestTraffic validation tests here. Set the test result
  // to "Succeeded" for this tutorial.
  console.log('This is where AfterAllowTestTraffic validation tests happen.')
  validationTestResult = 'Succeeded'

  // Complete the AfterAllowTestTraffic hook by sending CodeDeploy the validation status
  var params = {
    deploymentId: deploymentId,
    lifecycleEventHookExecutionId: lifecycleEventHookExecutionId,
    status: validationTestResult, // status can be 'Succeeded' or 'Failed'
  }

  // Pass CodeDeploy the prepared validation test results.
  codedeploy.putLifecycleEventHookExecutionStatus(params, function (err, data) {
    if (err) {
      // Validation failed.
      console.log('AfterAllowTestTraffic validation tests failed')
      console.log(err, err.stack)
      // webhook.send({
      //   text: JSON.stringify(err),
      // })
      callback('CodeDeploy Status update failed')
    } else {
      // Validation succeeded.
      console.log('AfterAllowTestTraffic validation tests succeeded')
      // webhook.send({
      //   text: JSON.stringify(data),
      // })
      callback(null, 'AfterAllowTestTraffic validation tests succeeded')
    }
  })
}
