FROM python:3.12-alpine

WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY ../output_gender_masked.csv /app/
COPY dashboard.py /app/

EXPOSE 8501

ENTRYPOINT ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]

