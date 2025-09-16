import json
import pandas as pd
import joblib
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

def train_and_save_model():
    """
    Loads the dataset, trains a classification pipeline,
    and saves it to a file using joblib.
    """
    print("Loading dataset...")
    with open('dataset.json', 'r') as f:
        data = json.load(f)

    df = pd.DataFrame(data)
    X = df['code']
    y = df['genre']

    print("Defining model pipeline...")
    # Create a pipeline that first creates a bag-of-words representation
    # and then applies a Naive Bayes classifier.
    pipeline = Pipeline([
        ('vectorizer', CountVectorizer()),
        ('classifier', MultinomialNB())
    ])

    print("Training model...")
    pipeline.fit(X, y)

    print("Saving trained model to model.joblib...")
    joblib.dump(pipeline, 'model.joblib')
    print("Model training complete and saved successfully!")

if __name__ == "__main__":
    train_and_save_model()
