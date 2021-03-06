'''
When notify is not None, user is either created or commented on that anno.
When modified is not None, user is interacted with anno.
When notify and modified are None, user is mentioned in that anno.
last_read is used to find if user read it
'''

import datetime

from google.appengine.ext import ndb

from model.user import User
from model.anno import Anno
from helper.utils_enum import AnnoActionType
from message.user_message import UserMessage

class UserAnnoState(ndb.Model):
    user = ndb.KeyProperty(kind=User, required=True)
    anno = ndb.KeyProperty(kind=Anno, required=True)
    last_read = ndb.DateTimeProperty()
    created = ndb.DateTimeProperty(auto_now_add=True)
    modified = ndb.DateTimeProperty()
    notify = ndb.BooleanProperty(default=True)

    @classmethod
    def get(cls, user, anno):
        return cls.query(ndb.AND(cls.user == user.key, cls.anno == anno.key)).get()

    @classmethod
    def insert(cls, user, anno, type):
        entity = cls.get(user=user, anno=anno)
        if not entity:
            entity = cls(user=user.key, anno=anno.key)

        if type in [AnnoActionType.CREATED, AnnoActionType.COMMENTED]:
            entity.last_read = datetime.datetime.now()
            entity.modified = entity.last_read
            entity.notify = True if entity.notify is None else entity.notify
        elif type in [AnnoActionType.UPVOTED, AnnoActionType.FLAGGED]:
            entity.last_read = datetime.datetime.now()
            entity.modified = entity.last_read

        entity.put()
        return entity


    @classmethod
    def list_users_by_anno(cls, anno_id=None, anno_key=None, projection=[]):
        if not anno_key:
            anno = Anno.get_by_id(anno_id)
            anno_key = anno.key if anno else None

        users = []
        if anno_key:
            query = cls.query().filter(ndb.AND(cls.anno == anno_key, cls.notify == True))
            users = query.fetch(projection=projection)

        return users


    @classmethod
    def list_by_user(cls, user_key, limit=None):
        query = cls.query().filter(cls.user == user_key)
        query = query.filter(ndb.OR(cls.last_read == None, cls.modified != None))
        query = query.order(-cls.modified)

        if limit:
            result = query.fetch(limit, projection=[cls.anno])
        else:
            result = query.fetch(projection=[cls.anno])

        return result

    @classmethod
    def delete_by_anno(cls, anno_id=None, anno_key=None):
        if anno_key is None:
            anno = Anno.get_by_id(anno_id) if anno_id else None
            anno_key = anno.key if anno else None

        if anno_key:
            userannostates = cls.query(cls.anno == anno_key).fetch()
            userannostate_key_list = [ userannostate.key for userannostate in userannostates ]
            ndb.delete_multi(userannostate_key_list)

    @classmethod
    def update_last_read(cls, user, anno):
        entity = cls.get(user=user, anno=anno)

        if not entity:
            entity = cls(user=user.key, anno=anno.key, notify=False)

        entity.last_read = datetime.datetime.now()
        entity.put()
        return entity

    @classmethod
    def is_read(cls, user, anno):
        entity = cls.get(user=user, anno=anno)
        is_read = False

        if entity and entity.last_read and anno.last_update_time and \
            (entity.last_read >= anno.last_update_time):
            is_read = True

        return is_read

    @classmethod
    def last_activity_user(cls, anno):
        query = cls.query(ndb.AND(cls.anno == anno.key, cls.modified != None))
        last_activity = query.order(-cls.modified).get()

        user_message = None
        if last_activity and last_activity.user:
            user_info = last_activity.user.get()
            if user_info:
                user_message = UserMessage(display_name=user_info.display_name, image_url=user_info.image_url)

        return user_message
