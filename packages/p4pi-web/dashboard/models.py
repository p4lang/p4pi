from django.db import models

class Statistics(models.Model):
    name = models.CharField(max_length=25)
    time = models.CharField(max_length=25)
    value = models.FloatField()
