from flask import Flask, request, jsonify
import requests
import os
import json
import logging
import openai

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

openai.api_key = os.getenv("OPENAI_API_KEY")
SLACK_WEBHOOK  = os.getenv("SLACK_WEBHOOK_URL")


def ask_gpt4(pod_name, logs):
    prompt = f"""
    Kubernetes pod '{pod_name}' has crashed.
    Last 50 lines of logs:
    {logs}
    Respond ONLY in valid JSON:
    {{
        "diagnosis": "what went wrong in 1-2 sentences",
        "root_cause": "specific technical cause",
        "fix": "restart_pod or manual_review",
        "confidence": 0.95
    }}
    """
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a Kubernetes expert. Respond in valid JSON only."},
            {"role": "user",   "content": prompt}
        ],
        temperature=0.1
    )
    raw = response.choices[0].message.content
    raw = raw.replace("```json", "").replace("```", "").strip()
    return json.loads(raw)


def send_slack(pod_name, diagnosis, fix_applied, confidence):
    if fix_applied:
        color  = "#36a64f"
        status = "✅ Auto-fixed by AI"
    else:
        color  = "#ff0000"
        status = "🚨 Needs manual review"

    message = {
        "attachments": [{
            "color": color,
            "title": f"🤖 AI Healer — {pod_name}",
            "fields": [
                {"title": "Status",      "value": status,                              "short": True},
                {"title": "Confidence",  "value": f"{int(confidence * 100)}%",         "short": True},
                {"title": "Diagnosis",   "value": diagnosis.get("diagnosis", "Unknown"),"short": False},
                {"title": "Root Cause",  "value": diagnosis.get("root_cause","Unknown"),"short": False},
                {"title": "Action",      "value": diagnosis.get("fix", "None"),         "short": False}
            ],
            "footer": "AI DevOps Platform"
        }]
    }
    try:
        requests.post(SLACK_WEBHOOK, json=message)
        logger.info("Slack notification sent")
    except Exception as e:
        logger.error(f"Slack failed: {e}")


@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "ai-healer"}), 200


@app.route('/webhook', methods=['POST'])
def handle_alert():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data"}), 400

    for alert in data.get('alerts', []):
        labels    = alert.get('labels', {})
        pod_name  = labels.get('pod', 'unknown-pod')
        namespace = labels.get('namespace', 'default')

        logger.info(f"Processing alert for pod: {pod_name}")

        # Simulate logs since we are running locally
        logs = f"Pod {pod_name} in namespace {namespace} crashed unexpectedly."

        try:
            diagnosis = ask_gpt4(pod_name, logs)
        except Exception as e:
            logger.error(f"GPT call failed: {e}")
            diagnosis = {
                "diagnosis": "AI analysis failed",
                "root_cause": str(e),
                "fix": "manual_review",
                "confidence": 0.0
            }

        confidence  = diagnosis.get('confidence', 0.0)
        fix_applied = False

        send_slack(pod_name, diagnosis, fix_applied, confidence)

    return jsonify({"status": "processed"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5010)