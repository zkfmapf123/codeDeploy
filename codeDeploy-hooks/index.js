'use strict'

const AWS = require('aws-sdk')
const { IncomingWebhook } = require('@slack/webhook')
const codedeploy = new AWS.CodeDeploy({ apiVersion: '2014-10-06' })
const webhook = new IncomingWebhook('https://hooks.slack.com/services/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')

exports.handler = (event, context, callback) => {
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

      callback('CodeDeploy Status update failed')
    } else {
      // Validation succeeded.
      console.log('AfterAllowTestTraffic validation tests succeeded')

      // Send a message to Slack webhook
      webhook
        .send({
          text: JSON.stringify(data, null, 4),
        })
        .then(() => {
          console.log('Slack webhook message sent successfully.')
          callback(null, 'AfterAllowTestTraffic validation tests succeeded')
        })
        .catch((error) => {
          console.error('Error sending Slack webhook message:', error)
          callback(null, 'AfterAllowTestTraffic validation tests succeeded, but Slack webhook failed to send.')
        })
    }
  })
}
