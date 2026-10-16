from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.projects.models import Project
from apps.projects.services import create_default_protocol


@receiver(post_save, sender=Project)
def create_protocol_for_new_project(sender, instance, created, raw=False, **kwargs):
    if created and not raw:
        create_default_protocol(instance)
