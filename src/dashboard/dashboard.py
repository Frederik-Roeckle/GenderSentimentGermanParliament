import streamlit as st
import pandas as pd
import numpy as np

df_all = pd.read_csv("./output_gender_masked.csv")

st.title("Zwischen-Fragen")

protocols = sorted({p[:5] for p in df_all["source_file"].dropna().unique()})
selected_protocols = st.multiselect("Select protocols", protocols)

df = df_all.loc[df_all["source_file"].str[:5].isin(selected_protocols)].copy()
df = df[df["zwischenfrage_text"].notna()]

# Initialize persistent state once
if "current_row_idx" not in st.session_state:
    st.session_state.current_row_idx = None

def sample_question():
    if len(df) == 0:
        st.session_state.current_row_idx = None
        return
    st.session_state.current_row_idx = int(np.random.choice(df.index))

def check_pred(btn):
    row = df.loc[st.session_state.current_row_idx]
    if btn == row["current_gender"]:
        st.balloons()

# Button changes question
st.button("Next question", type="primary", on_click=sample_question)

# Optional: auto-pick first question once when filter becomes valid
if st.session_state.current_row_idx is None and len(df) > 0:
    st.session_state.current_row_idx = int(np.random.choice(df.index))

masked = st.toggle("Switch masked version")
st.markdown("***")

if st.session_state.current_row_idx is None:
    st.info("No question available for current filter.")
else:
    row = df.loc[st.session_state.current_row_idx]

    text_col = "zwischenfrage_text_masked_combined" if masked else "zwischenfrage_text"
    st.markdown(f'**"** {row[text_col]} **"**')


    st.markdown("***")

    if masked:
        st.markdown("Was this question directed towards a man or a woman?")
        col1, _, col2 = st.columns(3)
        col1.button("man", on_click=check_pred, args=["male"])
        col2.button("woman", on_click=check_pred, args=["female"])
    else:
        st.markdown(
            f"**{row['current_gender']}** (Speaker)  <-  **{row['interruptor_gender']}** (Interruptor)"
        )
        st.markdown(
            f"**{row['current_party']}** (Speaker)  <-  **{row['interruptor_party']}** (Interruptor)"
        )
