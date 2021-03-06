import logging
import webapp2

from google.appengine.api import search
from google.appengine.ext import ndb

from model.anno import Anno
from model.userannostate import UserAnnoState
from model.vote import Vote
from model.follow_up import FollowUp
from model.flag import Flag
from model.appinfo import AppInfo
from model.tags import Tag
from helper.utils import put_search_document
from helper.utils import OPEN_COMMUNITY
from helper.utils import extract_tags_from_text
from helper.utils_enum import SearchIndexName
from message.appinfo_message import AppInfoMessage


BATCH_SIZE = 50  # ideal batch size may vary based on entity size


class UpdateAnnoHandler(webapp2.RequestHandler):
    def get(self):
#         add_lowercase_appname()
#         delete_all_anno_indices()
        update_anno_schema()
#         update_followup_indices()
#         update_userannostate_schema_from_anno_action(cls=Vote)
#         update_userannostate_schema_from_anno_action(cls=FollowUp)
#         update_userannostate_schema_from_anno_action(cls=Flag)
        self.response.out.write("Schema migration successfully initiated.")


def delete_all_anno_indices():
    doc_index = search.Index(name=SearchIndexName.ANNO)
    start_id = None

    while True:
        document_ids = []
        documents = doc_index.get_range(start_id=start_id, include_start_object=True,
                                        limit=BATCH_SIZE, ids_only=True)

        for document in documents:
            document_ids.append(document.doc_id)
            start_id = document.doc_id

        if not document_ids:
            break

        doc_index.delete(document_ids)

    logging.info("Deleted all Anno indices")


def update_anno_schema(cursor=None):
    anno_list, cursor, more = Anno.query().fetch_page(BATCH_SIZE, start_cursor=cursor)

    anno_update_list = []
    for anno in anno_list:
        # updating anno schema for plugin
        if not anno.circle_level:
            anno.circle_level = 0
            anno_update_list.append(anno)

        # updating app for anno schema
#         if not anno.app:
#             appinfo = AppInfo.get(name=anno.app_name)
# 
#             if appinfo is None:
#                 appInfoMessage = AppInfoMessage(name=anno.app_name, version=anno.app_version)
#                 appinfo = AppInfo.insert(appInfoMessage)
# 
#             anno.app = appinfo.key
#             anno_update_list.append(anno)

        # updating anno schema for community
#         if not anno.community:
#             anno.community = None
#             anno_update_list.append(anno)

        # updating anno schema for anno_id
#         if not anno.anno_id:
#             anno.anno_id = anno.key.id()
#             anno_update_list.append(anno)

        # updating userannostate from anno
#         update_userannostate_schema_from_anno(anno)

        # updating anno index
#         regenerate_index(anno, SearchIndexName.ANNO)

        # extract tag
#         create_tags(anno.anno_text)

    if len(anno_update_list):
        ndb.put_multi(anno_update_list)

    if more:
        update_anno_schema(cursor=cursor)


def update_followup_indices(cursor=None):
    followup_list, cursor, more = FollowUp.query().fetch_page(BATCH_SIZE, start_cursor=cursor)

    for followup in followup_list:
#         regenerate_index(followup, SearchIndexName.FOLLOWUP)
        create_tags(followup.comment)

    if more:
        update_followup_indices(cursor=cursor)


def update_userannostate_schema_from_anno(anno):
    user = anno.creator.get()
    modified = anno.last_update_time
    if user:
        UserAnnoState.insert(user=user, anno=anno, modified=modified)


def regenerate_index(entity, search_index_name):
    put_search_document(entity.generate_search_document(), search_index_name)


def update_userannostate_schema_from_anno_action(cls, cursor=None):
    activity_list, cursor, more = cls.query()\
                                     .order(cls.created)\
                                     .fetch_page(BATCH_SIZE, start_cursor=cursor)

    for activity in activity_list:
        user = activity.creator.get()
        anno = activity.anno_key.get()
        modified = activity.created
        if user and anno:
            UserAnnoState.insert(user=user, anno=anno, modified=modified)

    if more:
        update_userannostate_schema_from_anno_action(cls=cls, cursor=cursor)


def add_lowercase_appname(cursor=None):
    appinfo_list, cursor, more = AppInfo.query().fetch_page(BATCH_SIZE, start_cursor=cursor)

    appinfo_update_list = []
    for appinfo in appinfo_list:
        if not appinfo.lc_name:
            appinfo.lc_name = appinfo.name.lower()
            appinfo_update_list.append(appinfo)

    if len(appinfo_update_list):
        ndb.put_multi(appinfo_update_list)

    if more:
        add_lowercase_appname(cursor=cursor)

def create_tags(text):
    tags = extract_tags_from_text(text.lower())
    for tag, count in tags.iteritems():
        Tag.add_tag_total(text=tag, total=count)
