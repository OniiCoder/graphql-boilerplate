import 'package:app_boilerplate/components/add_task.dart';
import 'package:app_boilerplate/components/todo_item_tile.dart';
import 'package:app_boilerplate/data/todo_fetch.dart';
import 'package:app_boilerplate/data/todo_list.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../model/todo_item.dart';

class Active extends StatefulWidget {
  const Active({Key key}) : super(key: key);

  @override
  _ActiveState createState() => _ActiveState();
}

class _ActiveState extends State<Active> {
  VoidCallback refetchQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Mutation(
          options: MutationOptions(
            documentNode: gql(TodoFetch.addTodo),
            update: (Cache cache, QueryResult result) {
              return cache;
            },
            onCompleted: (dynamic resultData) {
              refetchQuery();
            },
          ),
          builder: (RunMutation runMutation, QueryResult result) {
            return AddTask(
              onAdd: (value) {
                runMutation({'title': value, 'isPublic': false});
              },
            );
          },
        ),
        Expanded(
          child: Query(
            options: QueryOptions(
              documentNode: gql(TodoFetch.fetchActive),
            ),
            builder: (QueryResult result, {VoidCallback refetch, FetchMore fetchMore}) {
              refetchQuery = refetch;
              if(result.hasException) {
                return Text(result.exception.toString());
              }
              if(result.loading) {
                return Text('Loading');
              }

              final List<LazyCacheMap> todos = (result.data['todos'] as List<dynamic>).cast<LazyCacheMap>();

              return ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  dynamic responseData = todos[index];
                  return TodoItemTile(
                    item: TodoItem.fromElements(responseData["id"], responseData["title"], responseData["is_completed"]),
                    toggleDocument: TodoFetch.toggleTodo,
                    toggleRunMutation: {'id': responseData["id"], 'isCompleted': !responseData['is_completed']},
                    deleteDocument: TodoFetch.deleteTodo,
                    deleteRunMutation: {
                      'id': responseData["id"],
                    },
                    refetchQuery: refetchQuery,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
