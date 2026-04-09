FROM python:3.12-alpine

WORKDIR /app

COPY dashboard.py /app/
COPY requirements.txt /app/
COPY ../output_gender.csv /app/

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8501

ENTRYPOINT ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]

