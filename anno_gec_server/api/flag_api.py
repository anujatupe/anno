__author__ = 'topcircler'

import endpoints
from protorpc import remote
from protorpc import message_types
from protorpc import messages
from google.appengine.datastore.datastore_query import Cursor
from google.appengine.ext.db import BadValueError

from message.flag_message import FlagMessage
from message.flag_message import FlagListMessage
from model.flag import Flag
from model.user import User
from model.anno import Anno

from api.utils import get_endpoints_current_user


@endpoints.api(name='flag', version='1.0', description='Flag API',
               allowed_client_ids=[endpoints.API_EXPLORER_CLIENT_ID])
class FlagApi(remote.Service):
    """
    Class which defines Flag API v1.
    """

    @endpoints.method(FlagMessage, FlagMessage, path='flag', http_method='POST', name='flag.insert')
    def flag_insert(self, request):
        """
        Exposes an API endpoint to insert a flag for the current user.
        """
        current_user = get_endpoints_current_user()
        user = User.find_user_by_email(current_user.email()).get()
        if user is None:
            user = User.insert_user(current_user.email())

        anno = Anno.get_by_id(request.anno_id)
        if anno is None:
            raise endpoints.NotFoundException('No anno entity with the id "%s" exists.')

        flag = Flag()
        flag.anno_key = anno.key
        flag.creator = user.key
        flag.put()
        return flag.to_message()

    flag_with_id_resource_container = endpoints.ResourceContainer(
        message_types.VoidMessage,
        id=messages.IntegerField(2, required=True)
    )

    @endpoints.method(flag_with_id_resource_container, message_types.VoidMessage, path='flag/{id}',
                      http_method='DELETE', name='flag.delete')
    def flag_delete(self, request):
        """
        Exposes an API endpoint to delete an existing flag.
        """
        if request.id is None:
            raise endpoints.BadRequestException('id field is required.')
        flag = Flag.get_by_id(request.id)
        if flag is None:
            raise endpoints.NotFoundException('No flag entity with the id "%s" exists.' % request.id)
        flag.key.delete()
        return message_types.VoidMessage()

    @endpoints.method(flag_with_id_resource_container, FlagMessage, http_method='GET', path='flag/{id}',
                      name='flag.get')
    def flag_get(self, request):
        """
        Exposes an API endpoint to get a flag.
        """
        if request.id is None:
            raise endpoints.BadRequestException('id field is required.')
        flag = Flag.get_by_id(request.id)
        if flag is None:
            raise endpoints.NotFoundException('No flag entity with the id "%s" exists.' % request.id)
        return flag.to_message()

    flag_list_resource_container = endpoints.ResourceContainer(
        message_types.VoidMessage,
        cursor=messages.StringField(2),
        limit=messages.IntegerField(3)
    )

    @endpoints.method(flag_list_resource_container, FlagListMessage, path='flag', http_method='GET', name='flag.list')
    def flag_list(self, request):
        """
        Exposes an API endpoint to retrieve a list of flag.
        """
        limit = 10
        if request.limit is not None:
            limit = request.limit

        curs = None
        if request.cursor is not None:
            try:
                curs = Cursor(urlsafe=request.cursor)
            except BadValueError:
                raise endpoints.BadRequestException('Invalid cursor %s.' % request.cursor)

        if curs is not None:
            flags, next_curs, more = Flag.query().fetch_page(limit, start_cursor=curs)
        else:
            flags, next_curs, more = Flag.query().fetch_page(limit)

        items = [entity.to_message() for entity in flags]
        if more:
            return FlagListMessage(flag_list=items, cursor=next_curs.urlsafe(), has_more=more)
        else:
            return FlagListMessage(flag_list=items, has_more=more)
