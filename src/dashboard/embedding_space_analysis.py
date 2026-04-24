import streamlit as st
import spacy
from gensim.models import FastText
import pandas as pd
import numpy as np

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
    for name, model in models.items():
        st.write(f"In Parlament Generations {name} the word '{word}' has a orientation of {word_gender_orientation(word, model)}")
    


st.title("Embedding Space Analysis")
st.write("value < 1: bias towards female")
st.write("value > 1: bias towards male")


word = st.text_input("Enter word to analyze...")
if word:
    word_gender_over_time(word)


