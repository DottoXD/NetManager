import 'package:flutter/material.dart';
import 'package:netmanager/database/cell_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class CellEditorDialog extends StatefulWidget {
  final String plmn;

  const CellEditorDialog({super.key, required this.plmn});

  @override
  State<CellEditorDialog> createState() => _CellEditorDialogState();
}

class _CellEditorDialogState extends State<CellEditorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cells = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadCells();
  }

  Future<void> _loadCells() async {
    setState(() => _isLoading = true);

    final results = await CellDatabase.getCellsForPlmn(
      widget.plmn,
      searchQuery: _searchController.text,
    );

    setState(() {
      _cells = results;
      _isLoading = false;
    });
  }

  Future<void> _openEditModal(Map<String, dynamic> cell) async {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    final cidController = TextEditingController(text: cell["cid"].toString());
    final descController = TextEditingController(
      text: cell["description"] ?? "",
    );
    final latController = TextEditingController(
      text: cell["latitude"].toString(),
    );
    final lngController = TextEditingController(
      text: cell["longitude"].toString(),
    );
    final channelController = TextEditingController(
      text: cell["channelnumber"] != null
          ? cell["channelnumber"].toString()
          : "",
    );

    int networkGen = cell["networkgen"] ?? 2;

    final bool? saved = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text("${appLocalizations.edit} #${cell["cid"]}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cidController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.mapCellId,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField(
                      value: networkGen,
                      decoration: const InputDecoration(labelText: "Gen"),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text("2G")),
                        DropdownMenuItem(value: 3, child: Text("3G")),
                        DropdownMenuItem(value: 4, child: Text("4G")),
                        DropdownMenuItem(value: 5, child: Text("5G")),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => networkGen = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.cellDescription,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: latController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.cellLatitude,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lngController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.cellLongitude,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: channelController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.cellChannelNumber,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(appLocalizations.cancel),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await CellDatabase.updateCell(
                      id: cell["id"] as int,
                      cid: int.tryParse(cidController.text) ?? cell["cid"],
                      networkGen: networkGen,
                      latitude:
                          double.tryParse(latController.text) ??
                          cell["latitude"],
                      longitude:
                          double.tryParse(lngController.text) ??
                          cell["longitude"],
                      description: descController.text,
                      channelNumber: int.tryParse(channelController.text),
                    );
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(appLocalizations.close),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      _loadCells();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text("${appLocalizations.editDatabase} ${widget.plmn}"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: appLocalizations.cellSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCells();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _loadCells(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cells.isEmpty
                  ? Center(child: Text(appLocalizations.cellNoneFound))
                  : ListView.builder(
                      itemCount: _cells.length,
                      itemBuilder: (context, index) {
                        final cell = _cells[index];
                        final int cid = cell["cid"];
                        final int gen = cell["networkgen"];
                        final String desc = cell["description"] ?? "";

                        return ListTile(
                          dense: true,
                          title: Text("CID: $cid (${gen}G)"),
                          subtitle: Text(
                            desc.isNotEmpty
                                ? desc
                                : "${appLocalizations.cellLatitude}: ${cell["latitude"]}, ${appLocalizations.cellLongitude}: ${cell["longitude"]}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openEditModal(cell),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.close),
        ),
      ],
    );
  }
}
