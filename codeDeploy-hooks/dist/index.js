"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const aws_sdk_1 = __importDefault(require("aws-sdk"));
const codeDeploy = new aws_sdk_1.default.CodeDeploy({ apiVersion: '2014-10-06' });
const handler = (event, context, callback) => __awaiter(void 0, void 0, void 0, function* () {
    console.log(JSON.stringify(event, null, 4));
    const { DeploymentId: deploymentId, LifecycleEventHookExecutionId: lifecycleEventHookExecutionId } = event;
    const params = {
        deploymentId,
        lifecycleEventHookExecutionId,
        status: 'Succeeded',
    };
    codeDeploy.putLifecycleEventHookExecutionStatus(params, (err, data) => {
        if (err) {
            callback('Validation test failed');
        }
        else {
            callback(null, 'Validation test succeede');
        }
    });
});
exports.handler = handler;
