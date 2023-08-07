const AWS = require("aws-sdk");
const { IncomingWebhook } = require("@slack/webhook");
const codedeploy = new AWS.CodeDeploy({ apiVersion: "2014-10-06" });
const webhook = new IncomingWebhook(
  "https://hooks.slack.com/services/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"
);

exports.handler = async (event, context) => {
  console.log(event.lifecycleEvent);
  console.log("Entering AfterAllowTestTraffic hook.", event);

  // Read the DeploymentId and LifecycleEventHookExecutionId from the event payload
  const deploymentId = event.DeploymentId;
  const lifecycleEventHookExecutionId = event.LifecycleEventHookExecutionId;
  let validationTestResult = "Failed";

  // Perform AfterAllowTestTraffic validation tests here. Set the test result
  // to "Succeeded" for this tutorial.
  console.log("This is where AfterAllowTestTraffic validation tests happen.");
  validationTestResult = "Succeeded";

  try {
    // Complete the AfterAllowTestTraffic hook by sending CodeDeploy the validation status
    const params = {
      deploymentId: deploymentId,
      lifecycleEventHookExecutionId: lifecycleEventHookExecutionId,
      status: validationTestResult, // status can be 'Succeeded' or 'Failed'
    };

    // Pass CodeDeploy the prepared validation test results using async/await.
    await new Promise((resolve, reject) => {
      codedeploy.putLifecycleEventHookExecutionStatus(params, (err, data) => {
        if (err) {
          // Validation failed.
          console.log("AfterAllowTestTraffic validation tests failed");
          console.log(err, err.stack);
          reject("CodeDeploy Status update failed");
        } else {
          // Validation succeeded.

          console.log("AfterAllowTestTraffic validation tests succeeded");
          resolve("CodeDeploy State Update Succeeded");
        }
      });
    });

    console.log("hello world >> ", params);
    console.log(
      Buffer.from(params.lifecycleEventHookExecutionId, "base64").toString(
        "utf-8"
      )
    );
    console.log(context);

    await webhook.send({
      text: JSON.stringify(params),
    });

    return "Function execution completed successfully";
  } catch (error) {
    throw new Error(error);
  }
};
