import aws from 'aws-sdk'

const codeDeploy = new aws.CodeDeploy({ apiVersion: '2014-10-06' })

interface CodeDeployHookParams {
  deploymentId: string
  lifecycleEventHookExecutionId: string
  status: 'Succeeded' | 'Failed'
}

export const handler = async (event, context, callback) => {
  console.log(JSON.stringify(event, null, 4))

  const { DeploymentId: deploymentId, LifecycleEventHookExecutionId: lifecycleEventHookExecutionId } = event
  const params = {
    deploymentId,
    lifecycleEventHookExecutionId,
    status: 'Succeeded',
  }

  codeDeploy.putLifecycleEventHookExecutionStatus(params, (err, data) => {
    if (err) {
      callback('Validation test failed')
    } else {
      callback(null, 'Validation test succeede')
    }
  })
}
