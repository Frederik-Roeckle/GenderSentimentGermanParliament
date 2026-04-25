import streamlit as st
import spacy
from gensim.models import FastText
import pandas as pd
import numpy as np


if 'df' not in st.session_state:
    st.session_state['df'] = pd.DataFrame(data={"word": [], "P2-5": [], "P6-9": [], "P10-14": [], "P15-19": [],})
    st.session_state['df'] = st.session_state['df'].set_index("word")
@st.cache_resource
def load_models():
    model_2_5 = FastText.load("./models/parliament_fasttext_2_5.model")
    model_6_9 = FastText.load("./models/parliament_fasttext_6_9.model")
    model_10_14 = FastText.load("./models/parliament_fasttext_10_14.model")
    model_15_19 = FastText.load("./models/parliament_fasttext_15_19.model")
    return {"2-5": model_2_5, "6-9": model_6_9, "10-14": model_10_14, "15-19": model_15_19}

def word_gender_orientation(word, model):
    return np.dot(model.wv.get_vector(word, norm=True), (model.wv.get_mean_vector(["herr", "kollege", "mann"], post_normalize=True) - model.wv.get_mean_vector(["frau", "kollegin", "dame"], post_normalize=True)))

def word_gender_over_time(word):
    models = load_models()
    if word in st.session_state['df'].index:
        return
    data = {}
    for name, model in models.items():
        data[f"P{name}"] = word_gender_orientation(word, model)
    h_df = pd.DataFrame(data, index=[word])
    st.session_state['df'] = pd.concat([h_df, st.session_state['df']])


st.title("Embedding Space Analysis")
st.write("This dashboard provides insights on the projection of specific words in the embedding spaces from the four parlament generations.")
st.write("The projection is calculated as the normalized dot product between the word and the difference between the mean vectors of v1(herr, kollege, mann) and v2(frau, kollegin, dame).")
st.write("value < 1: bias towards female")
st.write("value > 1: bias towards male")


word = st.text_input("Enter word to analyze...")
if word:
    word_gender_over_time(word)


st.dataframe(st.session_state['df'].style.highlight_between(left=0.25, right=1, color="lightblue").highlight_between(left=-1, right=-0.25, color="pink"))


