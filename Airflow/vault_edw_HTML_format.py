import pandas as pd
from airflow.hooks.mssql_hook import MsSqlHook


def get_HTML_on_vault_format(p_msg_text, p_html_tbl):

    html_str = '''
                    <html>
                    <head>
                    <style>
                        table {
                            border-collapse: collapse;
                        }
                        th {
                            background-color: #f2f2f2;
                        }
                        td, th {
                            border: 1px solid #ddd;
                            padding: 8px;
                        }
                        tr:nth-child(even) {
                            background-color: #f2f2f2;
                        }
                    </style>
                    </head>
                    <body>                    
                        <br>
                        <div style="text-align: center;">
                            <img data-imagetype="External" src="https://d2j09jzq254cyj.cloudfront.net/vault-logo.png" border="0" alt="Vault" style="width:65.99pt;height:47.99pt;">
                        </div>
                        <br><br><br>
                        ''' + p_msg_text + '''
                        <br><br>
                        ''' + p_html_tbl + '''
                        <br>
                        <td style="padding:0 18pt;word-break:break-word;">
                            <p style="margin-right:0;margin-bottom:0pt;margin-left:0;line-height:18.0pt;"><span style="color:#353535;font-size:12pt;font-family:Segoe UI,sans-serif;">This is an auto-generated message. If you have any questions, please reach out to <a href="mailto:itdatateam@vault.insurance">itdatateam@vault.insurance</a></span></p>
                            <p style="margin:0;line-height:18.0pt;"><span> <br> Sincerely,</span></p>
                            <p style="font-size:11pt;font-family:Calibri,sans-serif;margin:0;line-height:18.0pt;"><b><span style="color:#B31B34;font-size:12pt;font-family:Segoe UI,sans-serif;">Vault Data Team</span></b></p>
                            <p style="margin-right:0;margin-bottom:18pt;margin-left:0;line-height:18.0pt;"><span style="color:#353535;font-size:12pt;font-family:Segoe UI,sans-serif;">For issues please contact <br> <a href="https://nam10.safelinks.protection.outlook.com/?url=https%3A%2F%2Fvaultinsurance.atlassian.net%2Fservicedesk%2Fcustomer%2Fportal%2F1&data=05%7C02%7CSandeep.Gundreddy%40vault.insurance%7C6d7f90fb52214d05bb6b08dc28ae577d%7C348d7f3f9dec4a47a2a1d314cc2e5774%7C0%7C0%7C638429977650003544%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C0%7C%7C%7C&sdata=dZM%2BXRP4IvO4fsKj72GcM9yeXusVDKaHuY7lErzXYwA%3D&reserved=0">Vault Insurance IT Support</a> </span></p>
                        </td>
                    </body>
                    </html>
                    '''
    return html_str


def get_sp_success_data_HTML(process_nm_list, msg_text):

    conn_str = MsSqlHook(mssql_conn_id="Vault_EDW")
    process_nm_str = ", ".join(f"'{value}'" for value in process_nm_list)
    qry = f"""SELECT etl_audit_sk, audit.process_nm as process_name, process_start_ts as process_start_date, process_end_ts as process_end_date, record_ct as record_count, parameter_desc as extract_filter
                FROM edw_core.tetl_audit AS audit
                INNER JOIN (SELECT process_nm, MAX(etl_audit_sk) AS last_sk FROM edw_core.tetl_audit WHERE process_nm in ({process_nm_str}) GROUP BY process_nm) AS last
                ON audit.etl_audit_sk = last.last_sk
                WHERE status_desc = 'Success'
                ORDER BY process_start_ts DESC

            """

    df = conn_str.get_pandas_df(qry)
    html_tbl = df.to_html(index=False, justify='center', max_rows=1000)
    html_str = get_HTML_on_vault_format(msg_text, html_tbl)

    return html_str


def get_sp_error_data_HTML(process_nm_list, msg_text):

    conn_str = MsSqlHook(mssql_conn_id="Vault_EDW")
    process_nm_str = ", ".join(f"'{value}'" for value in process_nm_list)
    qry = f"""SELECT etl_audit_sk, audit.process_nm as process_name, process_start_ts as process_start_date, error_message_desc as error_message_description
                FROM edw_core.tetl_audit AS audit
                INNER JOIN (SELECT process_nm, MAX(etl_audit_sk) AS last_sk FROM edw_core.tetl_audit WHERE process_nm in ({process_nm_str}) GROUP BY process_nm) AS last
                ON audit.etl_audit_sk = last.last_sk
                WHERE status_desc = 'Failure'
                ORDER BY process_start_ts DESC

            """

    df = conn_str.get_pandas_df(qry)
    html_tbl = df.to_html(index=False, justify='center', max_rows=1000)
    html_str = get_HTML_on_vault_format(msg_text, html_tbl)

    return html_str


def get_vault_data_HTML(sql_qry, msg_text):

    conn_str = MsSqlHook(mssql_conn_id="Vault_EDW")

    df = conn_str.get_pandas_df(sql_qry)
    html_tbl = df.to_html(index=False, justify='center', max_rows=1000)
    html_str = get_HTML_on_vault_format(msg_text, html_tbl)

    return html_str


def get_release_notes_data_HTML(sql_qry, msg_text):

    conn_str = MsSqlHook(mssql_conn_id="Vault_EDW")

    df = conn_str.get_pandas_df(sql_qry)
    html_tbl = df.to_html(index=False, justify='center', max_rows=4000)
    html_tbl = html_tbl.replace('<th>', '<th style="background-color: #9D0208; color: white;">')
    html_tbl = html_tbl.replace('<table', '<table style="border-collapse: collapse; border: 2px solid black;"')
    html_tbl = html_tbl.replace('<td', '<td style="border: 2px solid black;"')
    html_str = get_HTML_on_vault_format(msg_text, html_tbl)

    return html_str


if __name__ == "__main__":
    print('*****name == main******')

    