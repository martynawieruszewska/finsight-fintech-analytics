from sklearn.metrics import (
    recall_score,
    precision_score,
    f1_score,
    confusion_matrix
)

# Model evaluation
def evaluate_model(model, X, y, experiment):
    y_pred = model.predict(X)
    recall = recall_score(y, y_pred)
    precision = precision_score(y, y_pred)
    f1 = f1_score(y, y_pred)
    conf_matrix = confusion_matrix(y, y_pred)

    evaluation = {
        "experiment": experiment,
        "recall": recall,
        "precision": precision,
        "f1": f1,
        "confusion_matrix": conf_matrix
    }
                  
    return evaluation

    
    