import streamlit as st
from utils_logging import logger


def main():
    logger.info("Home page loaded.")

    st.write("# Hey there 👋 I am your AI Assistant")

    st.markdown(
        """
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="https://d2j09jzq254cyj.cloudfront.net/vault-logo.png" width="250px">
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown(
        """
        <div style="
      background-color: #FFF3CD;
      color: #664D03;
      padding: 20px;
      border-radius: 10px;
      border-left: 5px solid #FFC107;
      margin: 20px 0;
    ">
          <h4 style="margin-top: 0; color: #664D03;">⚠️ Disclaimer</h4>
          <p>
            This application uses AI to interpret and analyze data. While we strive for accuracy, 
            the AI-generated responses may not always be precise or complete. 
            Always verify important insights and decisions with your team. 
            Results should be used as guidance rather than definitive answers.
          </p>
        </div>
        """,
        unsafe_allow_html=True,
    )


if __name__ == "__main__":
    main()
