import { CodeDeploy } from 'aws-sdk'

const codeDeploy = new CodeDeploy({ apiVersion: '2014-10-06' })

export const handler = async (event, context, callback) => {
  console.log('hello world')
  console.log(JSON.stringify(event, null, 4))

  const { DeploymentId: deploymentId, LifecycleEventHookExecutionId: lifecycleEventHookExecutionId } = event
  const params = {
    deploymentId,
    lifecycleEventHookExecutionId,
    status: 'Succeeded',
  }

  codeDeploy.putLifecycleEventHookExecutionStatus(params, (err, data) => {
    console.log(err, data)
    if (err) {
      callback('Validation test failed')
    } else {
      callback(null, 'Validation test succeede')
    }
  })
}
