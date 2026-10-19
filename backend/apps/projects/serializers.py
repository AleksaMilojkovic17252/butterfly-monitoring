import json

from rest_framework import serializers

from apps.projects.models import Project, ProjectProtocol


class ProjectProtocolSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectProtocol
        exclude = ["created_by", "updated_by", "project"]
        read_only_fields = [f.name for f in ProjectProtocol._meta.fields]


class ProjectSerializer(serializers.ModelSerializer):
    period = serializers.SerializerMethodField()
    # Annotated by the view: live transects, inactive ones included.
    transect_count = serializers.IntegerField(read_only=True)
    area = serializers.SerializerMethodField()
    protocol = ProjectProtocolSerializer(read_only=True)

    class Meta:
        model = Project
        fields = [
            "id",
            "name",
            "description",
            "start_date",
            "end_date",
            "period",
            "default_crs",
            "active",
            "transect_count",
            "area",
            "taxon_list_version",
            "protocol",
            "server_version",
            "deleted_at",
        ]
        read_only_fields = fields

    def get_period(self, project) -> dict:
        return {"start_date": project.start_date, "end_date": project.end_date}

    def get_area(self, project) -> dict | None:
        """The study area as a GeoJSON geometry, or null."""
        return json.loads(project.area.geojson) if project.area else None
