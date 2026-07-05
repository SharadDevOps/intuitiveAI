# intuitiveAI


## Monitoring & Alerting

The environment provisions one metric alert rule via the `monitoring` module:

**VM Availability Alert** (`alert-vm-availability-intai-wa-dev-cus`)

- **What it watches:** the platform-level `VmAvailabilityMetric` for the web-app VM.
- **Condition:** fires when average availability drops below 1 (i.e. the VM becomes
  unhealthy or unreachable) over a 5-minute window, evaluated every minute.
- **Why it's meaningful:** this VM is the single host serving the HTTPS application.
  If it stops reporting healthy, the service is down — this alert surfaces that within
  minutes rather than waiting for a user report. `VmAvailabilityMetric` is a platform
  metric, so it requires no in-guest agent.
- **Action:** the alert routes to an action group (`ag-intai-wa-dev-cus`). An email
  receiver can be enabled in the module to deliver notifications; it is left commented
  in dev.

**Production enhancement:** in production I would add an application-layer HTTP health
check probing `https://<vm-ip>/health` on a schedule (via Application Insights
availability tests or a Log Analytics query alert). VM-availability catches host
failure, but an HTTP probe also catches the case where the VM is up but nginx has
stopped — application-level coverage the platform metric can't provide.