import streamlit as st

nav = st.navigation([
    st.Page("asked_question_analysis.py", title="Asked Question Analysis"),
    st.Page("embedding_space_analysis.py", title="Embedding Space Analysis")
])

nav.run()