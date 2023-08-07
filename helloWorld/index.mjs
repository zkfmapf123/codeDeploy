import { IncomingWebhook } from "@slack/webhook";

const webhook = new IncomingWebhook(
  "https://hooks.slack.com/services/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"
);

/**
 * use EventBridge
 *  {
 *    "source": ["aws.codedeploy"],
 *    "detail-type": ["CodeDeploy Deployment State-change Notification"],
 *    "detail": {
 *    "state": ["START", "STOP", "FAILURE", "SUCCESS", "READY"]
 *  }
 */
export const handler = async (event) => {
  console.log(JSON.stringify(event, null, 4));

  await webhook.send({
    text: JSON.stringify(event.detail),
  });

  // TODO implement
  const response = {
    statusCode: 200,
    body: JSON.stringify("Hello from Lambda!"),
  };
  return response;
};
