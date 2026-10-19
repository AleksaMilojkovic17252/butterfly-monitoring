"""Catalogue rows as pulled to the phone (T025). Push (T026) uses the same classes."""

from rest_framework import serializers

from apps.catalogues.models import HabitatType, ManagementType, PlantTaxon, Taxon, TaxonListVersion


class TaxonListVersionSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaxonListVersion
        exclude = ["created_by", "updated_by"]


class TaxonSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = Taxon
        exclude = ["created_by", "updated_by"]


class PlantTaxonSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlantTaxon
        exclude = ["created_by", "updated_by"]


class HabitatTypeSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = HabitatType
        exclude = ["created_by", "updated_by"]


class ManagementTypeSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = ManagementType
        exclude = ["created_by", "updated_by"]
