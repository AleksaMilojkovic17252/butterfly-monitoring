from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from apps.catalogues.services import current_list_version
from apps.projects.models import Project
from apps.projects.services import create_default_protocol


@receiver(post_save, sender=Project)
def create_protocol_for_new_project(sender, instance, created, raw=False, **kwargs):
    if created and not raw:
        create_default_protocol(instance)


@receiver(pre_save, sender=Project)
def default_taxon_list_version(sender, instance, raw=False, **kwargs):
    """A new project uses the current butterfly list release, if there is one."""
    if instance._state.adding and not raw and instance.taxon_list_version_id is None:
        instance.taxon_list_version = current_list_version()
