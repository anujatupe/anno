__author__ = "rekenerd"

'''
Community API implemented using Google Cloud Endpoints.
'''

import endpoints
from protorpc import message_types
from protorpc import messages
from protorpc import remote

from api.utils import anno_js_client_id
from api.utils import get_user_from_request
from api.utils import userStatusType
from message.community_message import CommunityMessage
from message.community_message import CommunityAppInfoMessage
from message.community_message import CommunityUserMessage
from message.community_message import CommunityUserListMessage
from message.community_message import CommunityUserRoleMessage
from message.community_message import CommunityInviteMessage
from message.user_message import UserMessage
from message.common_message import ResponseMessage
from message.common_message import InviteResponseMessage
from model.community import Community
from model.userrole import UserRole
from model.user import User
from model.invite import Invite

@endpoints.api(name="community", version="1.0", description="Community API",
               allowed_client_ids=[endpoints.API_EXPLORER_CLIENT_ID, anno_js_client_id])
class CommunityApi(remote.Service):

    community_with_id_resource_container = endpoints.ResourceContainer(
        message_types.VoidMessage,
        id=messages.IntegerField(2, required=True),
        include_invite=messages.BooleanField(3, default=False)
    )

    community_welcome_msg_resource_container = endpoints.ResourceContainer(
        message_types.VoidMessage,
        id=messages.IntegerField(2, required=True),
        welcome_msg=messages.StringField(3, required=True)
    )

    @endpoints.method(community_with_id_resource_container, CommunityMessage,
                      path="community/{id}", http_method="GET", name="community.get")
    def community_get(self, request):
        return Community.getCommunity(request.id)

    @endpoints.method(CommunityMessage, ResponseMessage, path="community",
                      http_method="POST", name="community.insert")
    def community_insert(self, request):
        resp = Community.insert(request)
        return ResponseMessage(success=True, msg=resp)

    @endpoints.method(CommunityAppInfoMessage, ResponseMessage, path="app",
                      http_method="POST", name="app.insert")
    def app_insert(self, request):
        resp = Community.addApp(request)
        return ResponseMessage(success=True if resp else False)

    @endpoints.method(community_with_id_resource_container, CommunityUserListMessage,
                      path="userlist/{id}", http_method="GET", name="user.list")
    def user_list(self, request):
        community_user_message_list = []

        status = userStatusType.get("accepted")
        userroles = UserRole.community_user_list(request.id)
        for userrole in userroles:
            user = userrole.user.get()
            if user:
                user_message = UserMessage(id=user.key.id(), display_name=user.display_name, user_email=user.user_email)
                community_user_message = CommunityUserMessage(user=user_message, role=userrole.role, status=status)
                community_user_message_list.append(community_user_message)

        if request.include_invite:
            status = userStatusType.get("pending")
            from model.invite import Invite
            invited_users = Invite.list_by_community(request.id)
            for invited_user in invited_users:
                user_message = UserMessage(display_name=invited_user.name, user_email=invited_user.email)
                community_user_message = CommunityUserMessage(user=user_message, role=invited_user.role, status=status)
                community_user_message_list.append(community_user_message)

        return CommunityUserListMessage(user_list=community_user_message_list)

    @endpoints.method(CommunityUserRoleMessage, ResponseMessage, path="user",
                      http_method="POST", name="user.insert")
    def insert_user(self, request):
        user = get_user_from_request(user_id=request.user_id, user_email=request.user_email)
        community = Community.get_by_id(request.community_id)
        role = request.role if request.role else None

        if user and community:
            resp = UserRole.insert(user, community, role)

        return ResponseMessage(success=True if resp else False)

    @endpoints.method(CommunityUserRoleMessage, ResponseMessage, path="user",
                      http_method="DELETE", name="user.delete")
    def delete_user(self, request):
        user = get_user_from_request(user_id=request.user_id, user_email=request.user_email)
        community = Community.get_by_id(request.community_id)
        success = False

        if user and community:
            UserRole.delete(user, community)
            success = True

        return ResponseMessage(success=success)

    @endpoints.method(CommunityUserRoleMessage, ResponseMessage, path="user/edit_role",
                      http_method="POST", name="user.edit_role")
    def edit_user_role(self, request):
        user = get_user_from_request(user_id=request.user_id, user_email=request.user_email)
        community = Community.get_by_id(request.community_id)

        if user and community:
            resp = UserRole.edit(user, community, request.role)

        return ResponseMessage(success=True if resp else False)

    @endpoints.method(community_welcome_msg_resource_container, ResponseMessage, path="edit_welcome_msg/{id}",
                      http_method="POST", name="community.edit_welcome_msg")
    def edit_welcome_msg(self, request):
        community = Community.get_by_id(request.id)

        if community:
            community.welcome_msg = request.welcome_msg
            community.put()
            return ResponseMessage(success=True)
        else:
            return ResponseMessage(success=False)

    @endpoints.method(CommunityInviteMessage, InviteResponseMessage, path="invite",
                      http_method="POST", name="invite.create")
    def invite_user(self, request):
        recipients, subject, message = Invite.create(request)
        return InviteResponseMessage(recipients=recipients, subject=subject, message=message)
