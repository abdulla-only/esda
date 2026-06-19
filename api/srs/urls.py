from django.urls import path

from .views import GradeView, StudyQueueView

urlpatterns = [
    path("study/queue", StudyQueueView.as_view(), name="study-queue"),
    path("study/grade", GradeView.as_view(), name="study-grade"),
]
