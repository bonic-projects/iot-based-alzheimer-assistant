import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../models/appuser.dart';
import '../../common/app_colors.dart';
import 'notice_sheet_model.dart';

class NoticeSheet extends StackedView<NoticeSheetModel> {
  final Function(SheetResponse)? completer;
  final SheetRequest request;

  const NoticeSheet({
    Key? key,
    required this.completer,
    required this.request,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    NoticeSheetModel viewModel,
    Widget? child,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    onChanged: (value) => viewModel.searchUsers(value),
                    controller: viewModel.messageController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by user name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: viewModel.isBusy
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.hasError
                          ? Center(child: Text(viewModel.error.toString()))
                          : ListView.builder(
                              itemCount: viewModel.users.length,
                              itemBuilder: (context, index) {
                                final AppUser user = viewModel.users[index];
                                return Card(
                                  child: ListTile(
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      leading: CircleAvatar(
                                        backgroundImage: user.photoUrl != ""
                                            ? NetworkImage(user.photoUrl)
                                            : null,
                                        child: user.photoUrl == ""
                                            ? Text(user.fullName[0])
                                            : null,
                                      ),
                                      trailing: const Icon(
                                        Icons.add_box_rounded,
                                        color: kcPrimaryColor,
                                      ),
                                      onTap: () async {
                                        await viewModel.setUser(user);
                                        // show bottom sheet to enter chat name
                                        // String chatName = await

                                        // if (chatName != null) {
                                        //   await viewModel.createChat(user, chatName);

                                        completer!(SheetResponse(
                                          confirmed: true,
                                          data: user,
                                        ));
                                      }),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // Text(
          //   request.title!,
          //   style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          // ),
          // verticalSpaceTiny,
          // Text(
          //   request.description!,
          //   style: const TextStyle(fontSize: 14, color: kcMediumGrey),
          //   maxLines: 3,
          //   softWrap: true,
          // ),
          // verticalSpaceLarge,
        ],
      ),
    );
  }

  @override
  NoticeSheetModel viewModelBuilder(BuildContext context) => NoticeSheetModel();
}
