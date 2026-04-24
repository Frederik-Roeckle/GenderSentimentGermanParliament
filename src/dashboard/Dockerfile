FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt /app/
# RUN apk add --no-cache build-base
# RUN apk add --no-cache libc-dev
# RUN pip install -U pip
RUN pip install --no-cache-dir -r requirements.txt

COPY ../output_gender_masked.csv /app/
COPY asked_question_analysis.py /app/
COPY embedding_space_analysis.py /app/
COPY main.py /app/
COPY /models/ /app/models/

EXPOSE 8501

ENTRYPOINT ["streamlit", "run", "main.py", "--server.port=8501", "--server.address=0.0.0.0"]

