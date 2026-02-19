"""
Confirm Pause/Unpause Plugin for Apache Airflow 2.7.x

Adds a confirmation dialog to the pause/unpause toggle on both:
  - DAGs list view  (toggles with id="toggle-<dag_id>")
  - DAG detail view (toggle with id="pause_resume")

Intercepts clicks in capture phase. If cancelled, preventDefault() stops
the toggle and Airflow's JS never fires. If confirmed, normal flow continues.

Install: drop into $AIRFLOW_HOME/plugins/ and restart the webserver.
"""

import gzip
from airflow.plugins_manager import AirflowPlugin
from flask import Blueprint

CONFIRM_PAUSE_JS = r"""
(function(){
  function buildMessage(dagId, currentlyActive){
    var action=currentlyActive?"PAUSE":"UNPAUSE";
    return 'Are you sure you want to '+action+' the DAG "'+dagId+'"?\n\n'+
      (currentlyActive
        ?"Pausing this DAG will stop the scheduler from creating new runs."
        :"Unpausing this DAG will allow the scheduler to create new runs.");
  }

  document.addEventListener("click",function(e){
    var input=e.target.closest?e.target.closest("input.switch-input"):null;
    if(!input||input.disabled)return;

    var dagId=input.getAttribute("data-dag-id")
      ||input.id.replace(/^toggle-/,"")
      ||"unknown";

    // When the click reaches the input, the checkbox has already been
    // toggled, so checked reflects the NEW state:
    //   checked=true  → was paused, now being unpaused (currentlyActive=false)
    //   checked=false → was active, now being paused   (currentlyActive=true)
    var currentlyActive=!input.checked;

    if(!confirm(buildMessage(dagId,currentlyActive))){
      e.preventDefault();
      e.stopImmediatePropagation();
    }
  },true);
})();
"""

blueprint = Blueprint("confirm_pause_unpause_dag", __name__)

@blueprint.after_app_request
def _inject_script(response):
    if not (response.content_type and "text/html" in response.content_type):
        return response
    try:
        is_gz = response.headers.get("Content-Encoding", "").lower() == "gzip"
        html = gzip.decompress(response.get_data()).decode() if is_gz else response.get_data(as_text=True)
        if "</body>" not in html:
            return response
        html = html.replace("</body>", f"<script>{CONFIRM_PAUSE_JS}</script></body>", 1)
        if is_gz:
            data = gzip.compress(html.encode())
            response.set_data(data)
            response.headers["Content-Length"] = len(data)
        else:
            response.set_data(html)
    except Exception:
        pass
    return response

class ConfirmPauseUnpauseDagPlugin(AirflowPlugin):
    name = "confirm_pause_unpause_dag_plugin"
    flask_blueprints = [blueprint]