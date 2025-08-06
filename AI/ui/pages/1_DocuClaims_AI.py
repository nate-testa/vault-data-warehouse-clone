def render_footer():
    st.markdown(
        """
        <style>
        .vault-footer {
            position: fixed;
            left: 0;
            bottom: 0;
            width: 100vw;
            background: transparent;
            z-index: 9999;
        }
        </style>
        <div class='vault-footer'>
            <div style='text-align: center; padding: 0.5rem 0 0.5rem 0; color: #888; font-size: 0.98rem;'>
                &copy; DocuClaims AI can make mistakes. Check important info.
            </div>
        </div>
        """,
        unsafe_allow_html=True
    )

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__) + "/.."))

import time
import requests
import streamlit as st
from dotenv import load_dotenv
from typing import Dict, List
from concurrent.futures import ThreadPoolExecutor, as_completed
from utils_logging import logger

load_dotenv()


PRIMARY_COLOR = "#DC2626"  # Main accent color (default: red)
USER_MESSAGE_COLOR = "#DC2626"  # User messages color (default: red)
BOT_MESSAGE_COLOR = "#FFFFFF"  # Light color for bot messages
BOT_MESSAGE_BG = "#F5F5F5"  # Light grey background for bot messages


# API endpoint configuration
API_BASE = os.environ.get("API_BASE_URL")
if not API_BASE:
    raise RuntimeError("Missing required environment variable: API_BASE_URL")

def fetch_model_options() -> list[str]:
    """Fetch model options from FastAPI backend."""
    try:
        response = requests.get(f"{API_BASE}/model_options")
        response.raise_for_status()
        logger.info("Fetched model options from API.")
        return response.json()
    except Exception as e:
        logger.error(f"Failed to fetch model options: {str(e)}")
        return []


def main():
    logger.info("DocuClaims AI page loaded.")

    # Page setup -----------------------------------------------------------------
    st.set_page_config(
        page_title="DocuClaims AI",
        page_icon="🤖",
        layout="wide",
    )


    # Initialise theme colour ----------------------------------------------------
    if "accent_color" not in st.session_state:
        st.session_state.accent_color = PRIMARY_COLOR

    # Fetch model options from API -----------------------------------------------
    st.session_state["model_options"] = fetch_model_options()

    # Apply CSS theme tweaks ------------------------------------------------------
    apply_custom_css()

    # Initialise chat‑related state ---------------------------------------------
    if "rag_messages" not in st.session_state:
        reset_session_state()

    # Static UI elements ----------------------------------------------------------
    show_header_and_sidebar()

    # **NEW**: File uploader lives just below the header and is therefore
    # independent of the scrolling chat history.
    display_file_uploader()
    logger.info("File uploader displayed.")
    display_chat_interface()
    logger.info("Chat interface displayed.")
    render_footer()
    logger.info("Footer rendered.")


# -----------------------------------------------------------------------------
# ⬇️  Styling helpers
# -----------------------------------------------------------------------------

def apply_custom_css():
    """Inject custom CSS to tweak Streamlit widgets."""
    accent_color = st.session_state.get("accent_color", PRIMARY_COLOR)
    st.markdown(
        f"""
        <style>
        :root {{
            --primary-color: {accent_color};
            --vault-bg: #f8fafc;
            --vault-card: #fff;
            --vault-shadow: 0 2px 16px 0 rgba(44,62,80,0.07);
            --vault-radius: 18px;
            --vault-font: 'Segoe UI', 'Roboto', 'Arial', sans-serif;
        }}
        html, body, .stApp {{
            background: var(--vault-bg) !important;
            font-family: var(--vault-font) !important;
        }}
        .stApp header {{
            background: linear-gradient(90deg, {accent_color} 60%, #22223b 100%) !important;
            box-shadow: var(--vault-shadow);
            border-bottom-left-radius: var(--vault-radius);
            border-bottom-right-radius: var(--vault-radius);
        }}
        .css-1d391kg, .css-k7vsyb {{
            background: #fff !important;
            border-radius: var(--vault-radius);
            box-shadow: var(--vault-shadow);
            margin-top: 1.5rem;
        }}
        .stSidebarContent {{
            padding-top: 2rem;
        }}
        .stButton button, .stButton>button {{
            border-radius: 24px !important;
            background: {accent_color} !important;
            color: #fff !important;
            font-weight: 600;
            box-shadow: 0 2px 8px 0 rgba(44,62,80,0.08);
            transition: background 0.2s;
        }}
        .stButton button:hover, .stButton>button:hover {{
            background: #22223b !important;
            color: #fff !important;
        }}
        .stButton button[data-testid="baseButton-secondary"] {{
            background: transparent !important;
            border: 1.5px solid #e0e0e0 !important;
            color: #22223b !important;
            min-height: 30px !important;
        }}
        [data-testid="stChatMessageContent"].user {{
            background: {accent_color} !important;
            color: #fff !important;
            border-radius: 18px 18px 4px 18px !important;
            padding: 12px 18px !important;
            font-size: 1.08rem;
            margin-bottom: 0.5rem;
            box-shadow: var(--vault-shadow);
        }}
        [data-testid="stChatMessageContent"].assistant {{
            background: #f3f4f6 !important;
            color: #22223b !important;
            border-radius: 18px 18px 18px 4px !important;
            padding: 12px 18px !important;
            font-size: 1.08rem;
            margin-bottom: 0.5rem;
            box-shadow: var(--vault-shadow);
        }}
        .stTextArea textarea, .stChatInputContainer textarea {{
            border-radius: 16px !important;
            border: 1.5px solid #e0e0e0;
            font-size: 1.08rem;
            background: #f8fafc;
        }}
        .stTextArea textarea:focus, .stChatInputContainer:focus-within textarea {{
            border-color: {accent_color};
            box-shadow: 0 0 8px {accent_color}40;
        }}
        .stChatInputContainer {{
            border: 1.5px solid #e0e0e0;
            border-radius: 24px;
            background: #fff;
            box-shadow: var(--vault-shadow);
            margin-bottom: 1.5rem;
        }}
        .stChatInputContainer:focus-within {{
            border-color: {accent_color};
            box-shadow: 0 0 8px {accent_color}40;
        }}
        .stMarkdown h1, .stMarkdown h2, .stMarkdown h3, .stMarkdown h4 {{
            font-family: var(--vault-font);
            font-weight: 700;
            color: {accent_color};
        }}
        .stMarkdown h1 {{ font-size: 2.2rem; }}
        .stMarkdown h2 {{ font-size: 1.5rem; }}
        .stMarkdown h3 {{ font-size: 1.2rem; }}
        .stMarkdown h4 {{ font-size: 1.1rem; }}
        .stAlert, .stSuccess, .stWarning, .stInfo {{
            border-radius: 12px !important;
            font-size: 1.05rem;
        }}
        .stDataFrame, .stExpander, .stForm {{
            border-radius: var(--vault-radius) !important;
            box-shadow: var(--vault-shadow);
            background: var(--vault-card);
        }}
        .stExpanderHeader {{
            font-weight: 600;
            color: {accent_color};
        }}
        .stDivider {{
            margin: 1.5rem 0 !important;
        }}
        .stSidebar .stMarkdown img {{
            filter: drop-shadow(0 2px 8px rgba(44,62,80,0.10));
        }}
        /* File-uploader card */
        .file-uploader-card {{
            border: 1.5px solid #e0e0e0;
            border-radius: 16px;
            background: #fff;
            box-shadow: var(--vault-shadow);
            padding: 1.2rem 1.2rem 1.5rem;
            margin-bottom: 1.5rem;
        }}
        </style>
        """,
        unsafe_allow_html=True,
    )


# -----------------------------------------------------------------------------
# ⬇️  Session‑state helpers
# -----------------------------------------------------------------------------

def reset_session_state():
    """Reset all the custom keys we store in st.session_state."""
    st.session_state.rag_messages = []
    st.session_state.rag_warnings = []
    st.session_state.file_uploaded = False
    st.session_state.uploaded_filename = None
    st.session_state.debug = False
    st.session_state.using_all_docs = True
    logger.info("Session state reset.")


# -----------------------------------------------------------------------------
# ⬇️  Static layout (header + sidebar)
# -----------------------------------------------------------------------------

def show_header_and_sidebar():
    model_options = st.session_state.get("model_options", [])

    # Ensure selected_model is valid
    if "selected_model" not in st.session_state or st.session_state.selected_model not in model_options:
        st.session_state.selected_model = model_options[0]

    # Branded header
    st.markdown(
        f"""
        <div style='background-color: {st.session_state.accent_color}; padding: 1rem; margin-bottom: 1rem; border-radius: 0.5rem;'>
            <h1 style='color: white; margin: 0;'>DocuClaims AI</h1>
        </div>
        """,
        unsafe_allow_html=True,
    )

    # Sidebar -------------------------------------------------------------------
    with st.sidebar:
        st.markdown(
            """
            <div style="text-align: center; margin-bottom: 20px;">
                <img src="https://d2j09jzq254cyj.cloudfront.net/vault-logo.png" width="180px">
            </div>
            """,
            unsafe_allow_html=True,
        )
        st.divider()

        # Model picker -----------------------------------------------------------
        st.session_state.selected_model = st.selectbox(
            "Select Model",
            model_options,
            index=model_options.index(st.session_state.selected_model)
            if st.session_state.selected_model in model_options
            else 0,
            key="model_select_box_rag",
        )
        st.divider()

        # Misc options -----------------------------------------------------------
        st.checkbox("Remember chat history", key="use_chat_history", value=True)
        # st.checkbox("Debug mode", key="debug")
        st.divider()

        if st.button("Clear Chat History", use_container_width=True):
            st.session_state.rag_messages = []
            st.session_state.rag_warnings = []
            st.rerun()

        if st.button("Reset Everything", use_container_width=True):
            reset_session_state()
            st.rerun()

        st.divider()

        # Theme selector ---------------------------------------------------------
        with st.expander("Customize Theme", expanded=False):
            _render_theme_picker()


def _render_theme_picker():
    """Render colour chips that allow the user to change the accent colour."""
    st.markdown("<small>Theme</small>", unsafe_allow_html=True)
    cols = st.columns(2)
    with cols[0]:
        st.markdown(
            f"""
            <div style="border: 2px solid {st.session_state.accent_color}; border-radius: 10px; padding: 5px; text-align: center;">
                <div style="color: {st.session_state.accent_color}; font-size: 14px;">☀️</div>
                <div style="color: {st.session_state.accent_color}; font-size: 12px;">Light</div>
            </div>
            """,
            unsafe_allow_html=True,
        )
    with cols[1]:
        st.markdown(
            """
            <div style="border: 1px solid #e0e0e0; border-radius: 10px; padding: 5px; text-align: center;">
                <div style="color: #6B46C1; font-size: 14px;">🌙</div>
                <div style="font-size: 12px;">Dark</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    st.markdown("<small>Accent color</small>", unsafe_allow_html=True)

    color_options = [
        {"name": "Purple", "hex": "#6B46C1"},
        {"name": "Violet", "hex": "#9333EA"},
        {"name": "Red", "hex": "#DC2626"},
        {"name": "Orange", "hex": "#F97316"},
        {"name": "Yellow", "hex": "#EAB308"},
        {"name": "Green", "hex": "#00A67E"},
        {"name": "Blue", "hex": "#3B82F6"},
    ]

    def update_color(color_hex: str):
        st.session_state.accent_color = color_hex
        st.rerun()

    cols = st.columns(len(color_options))
    for i, color_data in enumerate(color_options):
        color_hex = color_data["hex"]
        with cols[i]:
            is_selected = color_hex == st.session_state.accent_color
            if st.button(
                "",
                key=f"color_{i}",
                help=f"Select {color_data['name']} theme color",
                use_container_width=True,
                on_click=update_color if color_hex != "#RGB" else None,
                args=(color_hex,) if color_hex != "#RGB" else None,
            ):
                pass
            bg_style = color_hex if color_hex != "#RGB" else "linear-gradient(90deg, red, green, blue)"
            border = "1px solid black" if is_selected else "none"
            icon = "✓" if is_selected else ""
            st.markdown(
                f"""
                <div style="background: {bg_style}; 
                            width: 18px; height: 18px; 
                            border-radius: 50%; margin: auto; 
                            border: {border};
                            display: flex; align-items: center; justify-content: center;">
                    <span style="color: white; font-size: 10px;">{icon}</span>
                </div>
                """,
                unsafe_allow_html=True,
            )


# -----------------------------------------------------------------------------
# ⬇️  File uploader (NEW POSITION)
# -----------------------------------------------------------------------------

def display_file_uploader():
    """Render the file‑upload widget in a fixed position (always visible)."""
    logger.info("File uploader widget rendered.")

    with st.container():
        # st.markdown("<div class='file-uploader-card'>", unsafe_allow_html=True)

        col1, col2 = st.columns([3, 1])
        with col1:
            uploaded_files = st.file_uploader(
                "Upload your files",
                type=("pdf", "doc", "docx"),
                key="global_file_uploader",  # fixed key so it doesn't reset on rerun
                accept_multiple_files=True  # Allow multiple file uploads
            )
        with col2:
            st.write("")
            st.write("")
            upload_disabled = not uploaded_files
            if st.button(
                "Upload to Snowflake",
                use_container_width=True,
                disabled=upload_disabled,
            ):
                _handle_file_upload(uploaded_files)

        # If upload succeeded, show a small confirmation beneath the controls.
        if st.session_state.file_uploaded and st.session_state.uploaded_filename:
            st.success(f"Files uploaded: {', '.join(st.session_state.uploaded_filename)}")

        # st.markdown("</div>", unsafe_allow_html=True)


def _check_file_processing_status(file_name: str, timeout: int = 300, interval: int = 10):
    """Poll `/check_file_processed` until the file is done or the timeout is reached."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(f"{API_BASE}/check_file_processed/{file_name}")
            if r.status_code == 200:
                processed = r.json().get("processed")
                if processed is True:
                    return "processed"
                elif processed is False:
                    time.sleep(interval)
                    continue
            else:
                return "error"
        except Exception as exc:
            print(f"Polling error: {exc}")
            return "error"
    return "timeout" 

def render_status(file_status: dict[str, str]) -> str:
    html_rows = []
    for file, status in file_status.items():
        if status == "uploading":
            row = f"<span style='color: blue;'>🔵 {file}: {status}</span>"
        elif status == "processing":
            row = f"<span style='color: orange;'>⏳ {file}: {status}</span>"
        elif status == "processed":
            row = f"<span style='color: green;'>✔ {file}: {status}</span>"
        else:  # error | timeout
            row = f"<span style='color: red;'>❌ {file}: {status}</span>"
        html_rows.append(row)

    # Use <br> so each row renders on its own line
    return "<br>".join(html_rows)


def _handle_file_upload(uploaded_files):
    """Upload the selected files to the FastAPI backend and check their processing status in parallel."""
    logger.info(f"Handling upload for {len(uploaded_files) if uploaded_files else 0} files.")

    TERMINAL_STATES = {"processed", "error", "timeout"}

    if not uploaded_files:
        st.warning("Please select files to upload.")
        return

    st.session_state.uploaded_filename = []
    st.session_state.file_uploaded = False

    status_placeholder = st.empty()
    file_status = {file.name: "uploading" for file in uploaded_files}

    # Helper
    def upload_and_check(file):
        try:
            response = upload_file_to_snowflake(file)
            if response and response.get("message"):
                file_status[file.name] = "processing"
                processing_status = _check_file_processing_status(file.name)
                file_status[file.name] = processing_status
            else:
                file_status[file.name] = "error"
        except Exception:
            file_status[file.name] = "error"

    # Launch uploads in parallel
    with ThreadPoolExecutor(max_workers=min(8, len(uploaded_files))) as executor:
        futures = {executor.submit(upload_and_check, f): f.name for f in uploaded_files}

        # UI polling loop --------------------------------------------------
        while not all(state in TERMINAL_STATES for state in file_status.values()):
            status_placeholder.markdown(render_status(file_status), unsafe_allow_html=True)
            time.sleep(1)

        # Final one‑shot status paint
        status_placeholder.markdown(render_status(file_status), unsafe_allow_html=True)

        # Ensure background exceptions are raised
        for future in as_completed(futures):
            future.result()  # will raise if upload_and_check had an unhandled exc.


    # Mark successful uploads in session ----------------------------------
    processed_files = [f for f, s in file_status.items() if s == "processed"]
    if processed_files:
        st.session_state.uploaded_filename = processed_files
        st.session_state.file_uploaded = True
        logger.info(f"Files processed: {processed_files}")
    return file_status


# -----------------------------------------------------------------------------
# ⬇️  Chat interface
# -----------------------------------------------------------------------------

def display_chat_interface():
    """Render the chat conversation and input box."""
    logger.info("Chat interface rendered.")

    accent_color = st.session_state.get("accent_color", PRIMARY_COLOR)
    st.markdown(
        f"""
        <style>
        .stChatInputContainer {{
            border: 1px solid #e0e0e0;
            border-radius: 20px;
            padding: 5px;
            background-color: white;
        }}
        .stChatInputContainer:focus-within {{
            border-color: {accent_color};
            box-shadow: 0 0 5px {accent_color}40;
        }}
        </style>
        """,
        unsafe_allow_html=True,
    )

    # --- Conversation history ---------------------------------------------------
    display_conversation()

    # --- Chat input -------------------------------------------------------------
    user_input = st.chat_input("What would you like to know?")
    if user_input:
        process_user_message(user_input)


# -----------------------------------------------------------------------------
# ⬇️  Chat processing helpers
# -----------------------------------------------------------------------------

def process_user_message(prompt: str):
    """Append user prompt, query backend and display assistant response."""
    logger.info("Processing user message.")

    if not prompt.strip():
        st.warning("Please enter a prompt before running the question.", icon="⚠️")
        return

    # Store + render user message ----------------------------------------------
    user_message = {"role": "user", "content": prompt}
    st.session_state.rag_messages.append(user_message)
    with st.chat_message("user", avatar="🧑"):
        st.markdown(prompt)

    # Placeholder for assistant reply ------------------------------------------
    with st.chat_message("assistant", avatar="🤖"):
        message_placeholder = st.empty()
        with st.spinner("Fetching answer..."):
            message_history = get_chat_history() if st.session_state.use_chat_history else []
            selected_model = st.session_state.get("selected_model", "claude-4-sonnet")
            response = query_document(prompt, message_history, selected_model)

            if response and "answer" in response:
                answer_text = (
                    response.get("answer", "")
                    .replace("\\n", "\n")
                    .replace("\n", "\n")
                )
                assistant_response_text = f"**Model used:** `{selected_model}`\n\n{answer_text}"
                logger.info("Assistant response received from API.")
            else:
                assistant_response_text = (
                    "Sorry, I encountered an error processing your question. Please try again."
                )
                logger.error("Error in assistant response from API.")

            message_placeholder.markdown(assistant_response_text)
            assistant_message = {"role": "assistant", "content": assistant_response_text}
            st.session_state.rag_messages.append(assistant_message)


def display_message(content: List[Dict]):
    for item in content:
        if isinstance(item, str):
            st.markdown(item)


def display_conversation():
    if st.session_state.rag_warnings:
        for warning in st.session_state.rag_warnings:
            st.info(warning, icon="ℹ️")
        st.session_state.rag_warnings = []

    if not st.session_state.rag_messages:
        return

    for msg in st.session_state.rag_messages:
        avatar = "🧑" if msg["role"] == "user" else "🤖"
        with st.chat_message(msg["role"], avatar=avatar):
            display_message([msg["content"]])


# -----------------------------------------------------------------------------
# ⬇️  Backend helpers (upload + RAG query)
# -----------------------------------------------------------------------------

def upload_file_to_snowflake(file):
    try:
        files = {"file": (file.name, file.getvalue(), file.type)}
        response = requests.post(f"{API_BASE}/upload_file", files=files)
        response.raise_for_status()
        logger.info(f"File '{file.name}' uploaded to API.")
        return response.json()
    except requests.exceptions.HTTPError as http_exc:
        logger.error(f"HTTP error uploading file '{file.name}': {str(http_exc)}")
        raise http_exc
    except Exception as e:
        logger.error(f"Error uploading file '{file.name}': {str(e)}")
        st.error(f"Error uploading file: {str(e)}")
        return None


def query_document(question, message_history=None, model=None):
    try:
        payload = {"question": question, "chat_history": message_history}
        if model:
            payload["llm_model"] = model

        if st.session_state.debug:
            st.sidebar.markdown("### API Request")
            st.sidebar.json(payload)

        response = requests.post(f"{API_BASE}/rag_complete", json=payload)
        if response.status_code == 200:
            response_data = response.json()
            logger.info("Document query successful.")
            return response_data
        else:
            try:
                error_detail = response.json().get("detail", "Unknown error")
            except Exception:
                error_detail = response.text
            logger.error(f"Error processing question: {error_detail}")
            st.error(f"Error processing question: {error_detail}")
            return None
    except Exception as e:
        logger.error(f"Error processing question: {str(e)}")
        st.error(f"Error processing question: {str(e)}")
        return None


def get_chat_history(slide_window: int = 5):
    start_index = max(0, len(st.session_state.rag_messages) - slide_window)
    chat_history = [st.session_state.rag_messages[i]["content"] for i in range(start_index, len(st.session_state.rag_messages))]
    return chat_history


# -----------------------------------------------------------------------------
# ⬇️  Run!
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    main()
